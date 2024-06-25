import common;

struct KDTree (size_t d)
{
	Node!0 root_m; ///< the root of the k-D tree

	/*
	 * CTOR
	 */
	this (Point!d[] points)
	{
		root_m = new Node!0(points);
	}

	class Node (size_t split_dim)
	{
		Point!d p_m; ///< the single point this Node represents

		enum this_level = split_dim;           ///< the dimension (coordinate) this Node deals in (i.e. the level)
		enum next_level = (split_dim + 1) % d; ///< the split_dim the children should be instantiated with

		Node!next_level left_m;  ///< this Node's left child node
		Node!next_level right_m; ///< this Node's right child node

		/*
		 * CTOR
		 */
		this (Point!d[] points)
		{
			/* base case: we have assigned all of our points to Nodes in our tree */
			if (points.length == 0) return;

			/* sort the list of points */
			points.median_by_d!split_dim;

			/* get index of the median element */
			size_t median_index = points.length / 2;

			/* assign the median point to this node */
			p_m = points[median_index];

			/* split points by median and exclude median each recursion */
			auto l_half = points[0                 ..median_index];
			auto r_half = points[(median_index + 1)..$];

			/* construct children */
			if (l_half.length > 0)  left_m  = new Node!next_level(l_half);
			if (r_half.length > 0)  right_m = new Node!next_level(r_half);
		}
	}
	
	/**
	 * Returns a list of all points within a radius 'r' of a query point 'qp'
	 */
	Point!d[] range_query (Point!d qp, float r)
	{		
		void recurse (NodeType) (NodeType node)
		{
			if (node is null) return;

			if ( distance(node.p_m, qp) <= r ) res ~= node.p_m;
			
			if ( node.left_m !is null   &&  ( qp[node.this_level] - r  <=  node.p_m[node.this_level] ) ) {
				recurse(node.left_m);
			}

			if ( node.right_m !is null  &&  ( qp[node.this_level] + r  >=  node.p_m[node.this_level] ) ) {
				recurse(node.right_m);
			}
		}

		Point!d[] res;

		recurse(root_m);

		return res;
	}

	/**
	 * Returns a list of the 'k'-nearest points to a query point 'qp'
	 */
	Point!d[] knn_query(Point!d qp, int k)
	{
		void recurse (NodeType) (NodeType node, AABB!d box)
		{
			if (node is null) return;

			if ( queue.length < k ) {
				queue.insert(node.p_m);
			} else if( distance(qp, node.p_m) < distance(qp, queue.front()) ) {
				/* remove current farthest */
				queue.popFront();
				queue.insert(node.p_m);
			}

			AABB!d right_box = box;
			AABB!d left_box  = box;

			left_box.max [node.this_level] = node.p_m[node.this_level];
			right_box.min[node.this_level] = node.p_m[node.this_level];

			auto closest_right = closest!d(right_box, qp);
			auto closest_left  = closest!d(left_box, qp);

			if (node.left_m !is null) {
				if ( queue.length < k  ||  distance(qp, queue.front()) > distance(qp, closest_left) ) {
					recurse(node.left_m, left_box);
				}
			}

			if (node.right_m !is null) {
				if ( queue.length < k  ||  distance(qp, queue.front()) > distance(qp, closest_right) ) {
					recurse(node.right_m, right_box);
				}
			}
		}

		auto queue = makePriorityQueue!d(qp);

		AABB!d inf_box;
		inf_box.min[] = -float.infinity;
		inf_box.max[] =  float.infinity;

		recurse(root_m, inf_box);

		Point!d[] res = queue.release;

		res.sortByDistance(qp);

		return res;
	} // end of knn_query()

} // end of KDTree struct



import dumbknn;

unittest // kdtree.range_query()
{	
	enum d = 2;

    auto trainers = getGaussianPoints!d(1000);
    auto testers  = getUniformPoints!d(100);

    auto dumbknn = DumbKNN!d(trainers);
    auto kdtree  = KDTree!d(trainers);

	enum r = 0.2;

    foreach(qp; testers)
	{
        auto expect = dumbknn.rangeQuery(qp, r);
        auto result = kdtree.range_query(qp, r);
		expect.sortByDistance(qp);
		result.sortByDistance(qp);
        assert(result == expect);
    }
	writeln("test 3");
}

unittest // kdtree.range_query()
{
	enum d = 2;

    auto trainers = getGaussianPoints!d(1000);
    auto testers = getUniformPoints!d(100);

    auto dumbknn = DumbKNN!d(trainers);
    auto kdtree = KDTree!d(trainers);

	enum k = 10;

    foreach(qp; testers)
	{
        auto expect = dumbknn.knnQuery(qp, k);
        auto result = kdtree.knn_query(qp, k);
		expect.sortByDistance(qp);
		result.sortByDistance(qp);
        assert(result == expect);
    }
	writeln("test 4");
}
