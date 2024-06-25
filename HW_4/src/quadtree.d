import common;

struct QuadTree
{
	alias P2 = Point!2; // 2D points
	alias B2 = AABB!2;  // 2D boxes
	
	Node root_m; ///< root Node of quad tree

	/* QuadTree CTOR */
	this (P2[] points)
	{
		root_m = new Node(points, boundingBox(points));
	}

	class Node
	{
		P2[] pts_m;		///< list of points in this Node
		B2   box_m;     ///< the area this Node covers
		bool is_leaf_m;	///< whether this Node is a leaf or not

		Node q1_m;		///< "quadrant 1" child
		Node q2_m;		///< "quadrant 2" child
		Node q3_m;		///< "quadrant 3" child
		Node q4_m;		///< "quadrant 4" child

		enum threshold_m = 10; ///< greate than or equal to this threshold --> split

		/* Node CTOR */
		this (P2[] points, B2 box)
		{
			/* base case: make leaf */
			if (points.length < threshold_m)
			{
				pts_m = points.dup;
				box_m = box;
				is_leaf_m = true;
				return;
			}

			/* ELSE: make internal node and split points amongst children */

			/* assign fields for internal node */
			pts_m = [];
			box_m = box;
			is_leaf_m = false;

			/* compute "median" of box (perfect square --> same for x and y --> pick x) */
			float center = (box.min[0] + box.max[0]) / 2;

			/* create empty arrays to fill below */
			P2[] pts_q1, pts_q2, pts_q3, pts_q4;

			/* dole out points */
			foreach (const ref p ; points)
			{	
				/* readability */
				float x = p[0];
				float y = p[1];

				/* append points (in no particular order) to their respective boxes */
				if      (x >= center  &&  y >= center)  pts_q1 ~= p;
				else if (x >= center  &&  y <  center)  pts_q2 ~= p;
				else if (x <  center  &&  y <  center)  pts_q3 ~= p;
				/*      (x <  center  &&  y >= center) */
				else                                    pts_q4 ~= p;
			}

			/* (recursively) create child nodes and assign to parent */
			q1_m = new Node(pts_q1, boundingBox(pts_q1));
			q2_m = new Node(pts_q2, boundingBox(pts_q2));
			q3_m = new Node(pts_q3, boundingBox(pts_q3));
			q4_m = new Node(pts_q4, boundingBox(pts_q4));
		} // end CTOR
	} // end of Node class

	/**
	 * Returns a list of all points within a radius 'r' of a query point 'qp'
	 */
	P2[] range_query (P2 qp, float r)
	{	
		P2[] res;

		void recurse (Node node)
		{
			/* base case */
			if (node.is_leaf_m)
			{
				foreach (const ref p ; node.pts_m)
				{
					if (distance(qp, p) <= r)  res ~= p;
				}
			}

			/* recurse on all children which overlap with the range */
			else
			{
				/* range hack (square perfectly containing the circle defined by radius 'r') */
				B2 range = boundingBox( [ P2(qp-r), P2(qp+r) ] );

				if (overlaps(node.q1_m.box_m, range))  recurse(node.q1_m);
				if (overlaps(node.q2_m.box_m, range))  recurse(node.q2_m);
				if (overlaps(node.q3_m.box_m, range))  recurse(node.q3_m);
				if (overlaps(node.q4_m.box_m, range))  recurse(node.q4_m);
			}
		}

		recurse(root_m);

		return res;
	}

	/**
	 * Returns a list of the 'k'-nearest points to a query point 'qp'
	 */
	P2[] knn_query (P2 qp, int k)
	{
		auto queue = makePriorityQueue!2(qp);

		void recurse (Node node)
		{
			if (node.is_leaf_m)
			{
				foreach (const ref p ; node.pts_m)
				{
					if ( queue.length < k ) {
						queue.insert(p);
					} else if( distance(qp, p) < distance(qp, queue.front()) ) {
						/* removes farthest */
						queue.popFront();
						queue.insert(p);
					}
				}
			}
			else
			{
				if ( queue.length < k || overlaps(node.q4_m.box_m, boundingBox( [ P2(qp - (distance(qp, queue.front())) ), P2(qp + (distance(qp, queue.front())) ) ] )) ) recurse(node.q4_m);
				if ( queue.length < k || overlaps(node.q1_m.box_m, boundingBox( [ P2(qp - (distance(qp, queue.front())) ), P2(qp + (distance(qp, queue.front())) ) ] )) ) recurse(node.q1_m);
				if ( queue.length < k || overlaps(node.q3_m.box_m, boundingBox( [ P2(qp - (distance(qp, queue.front())) ), P2(qp + (distance(qp, queue.front())) ) ] )) ) recurse(node.q3_m);
				if ( queue.length < k || overlaps(node.q2_m.box_m, boundingBox( [ P2(qp - (distance(qp, queue.front())) ), P2(qp + (distance(qp, queue.front())) ) ] )) ) recurse(node.q2_m);
			}
		}

		recurse(root_m);

		P2[] res = queue.release;

		res.sortByDistance(qp);

		return res;
	}

	/**
	 * Returns a list of the 'k'-nearest points to a query point 'qp'
	 */
	bool overlaps (B2 qb, B2 range)
	{
		/* check for intersection in x-dimension */
		if (qb.max[0] < range.min[0]  ||  qb.min[0] > range.max[0])  return false;
		
		/* check for intersection in y-dimension */
		if (qb.max[1] < range.min[1]  ||  qb.min[1] > range.max[1])  return false;

		return true;
	}

} // end of QuadTree struct



import dumbknn;

unittest // quadtree.range_query()
{	
	enum d = 2;

    auto trainers = getGaussianPoints!d(1000);
    auto testers  = getUniformPoints!d(100);

    auto dumbknn  = DumbKNN!d(trainers);
    auto quadtree = QuadTree(trainers);

	enum r = 0.2;

    foreach(qp; testers)
	{
        auto expect = dumbknn.rangeQuery(qp, r);
        auto result = quadtree.range_query(qp, r);
		expect.sortByDistance(qp);
		result.sortByDistance(qp);
        assert(result == expect);
    }
	writeln("test 1");
}

unittest // quadtree.knn_query()
{
	enum d = 2;

    auto trainers = getGaussianPoints!d(1000);
    auto testers  = getUniformPoints!d(100);

    auto dumbknn  = DumbKNN!d(trainers);
    auto quadtree = QuadTree(trainers);

	enum k = 10;

    foreach(qp; testers)
	{
        auto expect = dumbknn.knnQuery(qp, k);
        auto result = quadtree.knn_query(qp, k);
		expect.sortByDistance(qp);
		result.sortByDistance(qp);
        assert(result == expect);
    }
	writeln("test 2");
}