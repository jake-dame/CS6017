/******************************************************************************
* \brief
*
* \file common.d
* \author
******************************************************************************/

public import std.stdio;
public import std.range;
public import std.array;
public import std.algorithm;
public import std.traits;
public import std.math;
public import std.datetime.stopwatch;
public import std.container.binaryheap;

/******************************************************************************
 * \struct Point
 *
 * Use like Point !d. See a 2-D example below
 *****************************************************************************/
struct Point (size_t d)
{
    float[d] coords_m;      ///< a 'd'-dimension set of coordinates
    alias coords_m this;

    Point opBinary (string op) (float x)
    {
        Point res;
        foreach (i ; 0..d) res[i] = mixin("coords_m[i] "~op~" x");
        return res;
    }

    Point opBinary (string op) (Point p)
    {
        Point res;
        foreach (i ; 0..d) res[i] = mixin("coords_m[i] "~op~" p.coords_m[i]");
        return res;
    }
}

/******************************************************************************
 * \struct Indices
 *
 * For the bucketing approach
 *****************************************************************************/
struct Indices (size_t d)
{
    size_t[d] coords_m;  ///< integer coordinates of a bucket
    alias coords_m this;
}

/******************************************************************************
 * \struct AABB
 *
 *
 *****************************************************************************/
struct AABB (size_t d)
{
    Point!d min; ///< bottom left corner
    Point!d max; ///< top right corner
}

/******************************************************************************
 * \brief
 *
 *
 *****************************************************************************/
float distance (T) (T a, T b) if (isInstanceOf!(Point, T) )
{
    auto pairs = a[].zip( b[] ); // [ (a_0, b_0), (a_1, b_1), ... ]
    auto squared_diffs = pairs.map!( x => (x[0] - x[1]) * (x[0] - x[1]) );
    auto sum = squared_diffs.sum();

    return sqrt(sum);
}

// unittest // common.distance()
// {
//     auto x = Point !2 ( [3, 0] );
//     auto y = Point !2 ( [0, -4] );

//     assert( distance(x, y) == 5 );
// }

/******************************************************************************
 * \brief
 *
 * Get the coordinates on the min and max corners of a list of points
 *****************************************************************************/
AABB!d boundingBox (size_t d) (Point!d[] points)
{
    AABB!d res;

    res.min[] =  float.infinity;
    res.max[] = -float.infinity;

    foreach (const ref p ; points)
    {
        foreach (i ; 0..d)
        {
            res.min[i] = min(res.min[i], p[i]);
            res.max[i] = max(res.max[i], p[i]);
        }
    }

    return res;
}

/******************************************************************************
 * \brief
 *
 * Return the point in an AABB to p.
 * This will be useful for the KNN methods of the tree data structures
 *****************************************************************************/
Point!d closest (size_t d) (AABB!d aabb, Point!d p)
{
    foreach (i ; 0..d) p[i] = clamp( p[i], aabb.min[i], aabb.max[i] );

    return p;
}

// unittest // common.closest()
// {
//     auto points = [ Point!2( [1,2] ), Point!2( [-2, 5] ) ];
//     auto aabb = boundingBox(points);

//     assert( aabb.min == Point!2( [-2, 2] ) );
//     assert( aabb.max == Point!2( [1, 5] ) );

//     /* Call closest using the normal function syntax */
//     assert( closest( aabb, Point!2( [0,0 ] ) ) == Point!2( [0,2] ) );

//     /* Call it using the method-like syntax... does the same thing */
//     assert( aabb.closest( Point!2( [0.5,3] ) ) == Point!2( [0.5,3] ) );
// }

/******************************************************************************
 * \brief
 * 
 * Used for the BucketKNN, so you can probably ignore this!
 * 
 * Takes in the indices of the bottom left/top right corners of a box
 * and returns all the buckets in that box/cube
 *
 * You'll want to use this to loop through all the buckets in a piece of your
 * bucketed data structure
 *
 * You can probably safely ignore looking at this implementation... it's ugly
 * look at the unittest below that uses it
 *****************************************************************************/
auto getIndicesRange (size_t d) (Indices!d start, Indices!d stop)
{
    auto helper (size_t N) () 
    {
        auto this_iota = iota( start[N], stop[N] + 1 ).map!(x => [x]);

        static
        if (N == d - 1) {
            return this_iota;
        } else {
            return cartesianProduct( this_iota, helper!(N + 1) () ).map!( 
                                     function(x) { return x[0] ~ x[1]; } );
        }
    }

    return helper!0().map!( 
           function Indices!d(x) { return Indices!d( x[0..d] ); } );
}

// unittest // common.getIndicesRange()
// {
//     auto btm_L = Indices !3 ([0, 2, 3]);
//     auto top_R = Indices !3 ([2, 3, 5]);

//     writeln("Indices between ", btm_L, " and ", top_R);
//     foreach (ind ; getIndicesRange(btm_L, top_R)) writeln(ind);
// }

/******************************************************************************
 * \brief
 * 
 * Partition the list of points so that the median is in the right place and the
 * left half has all points with a smaller coordinate in Sortingd
 * and the right half has all poitns with greater coordinate in sortingd
 *****************************************************************************/
auto median_by_d (size_t sort_d, size_t p_d) (Point !p_d [] points)
{
    return points.topN!( (a, b) => a[sort_d] < b[sort_d] ) (points.length / 2);
}

// unittest // common.median_by_d()
// {
//     auto points = [ Point!2([1,2]), 
//                     Point!2([3,1]), 
//                     Point!2([2,3]) ];

//     /* Partition based on x coordinate */
//     points.median_by_d!0;

//     /* 
//      * "median" had x coordinate 2,
//      * "left half" has the point with x coordinate less than 2
//      * "righ thalf" has the point with x coordinate greater than 2
//      */
//     assert( points == [ Point!2([1,2]),
//                         Point!2([2,3]),
//                         Point!2([3,1]) ] );

//     /* Partition based on y coordinate */
//     points.median_by_d !1;

//     /*
//      * Point with y coordinate of 2 is in the middle
//      * y coordinate 1 on the left side, y coorindate 3 on the right side
//      */
//     assert( points == [ Point!2([3,1]),
//                         Point!2([1,2]),
//                         Point!2([2,3]) ] );
// }

/******************************************************************************
 * \brief
 *
 * Partition the list of points so the front part has all the points with a smaller coordinate
 * in the sortingd, and the right part has all the points with greater coordinate in the sortingd
 * this returns the "right half".  See the unitTest for how to work with this
 *****************************************************************************/
auto partition_by_d (size_t sortingd, size_t Pointd) (Point !Pointd [] points, float splitValue )
{
    return points.partition !( x => x[sortingd] < splitValue );
}

// unittest // common.paritionBydimension()
// {
//     auto points = [ Point!2([1,2]),
//                     Point!2([3,1]),
//                     Point!2([2,3]) ];

//     auto r_half = points.partition_by_d!0(2.5);
//     auto l_half = points[ 0..$ - r_half.length ];

//     assert( r_half == [ Point !2 ([3,1]) ] );
//     assert( l_half.length == 2 ); /* Not sure what order they'll be in */

//     /* To partition by y coordinate, you'd use partition_by_d!1 instead of 0 */
// }

/******************************************************************************
 * \brief
 * 
 * returns a "max heap" keyed by distance to p.  pq.front is the point farthest from p
 * see below for how you might use it
 *****************************************************************************/
auto makePriorityQueue (size_t d) (Point !d p)
{
    Point !d [] storage;

    return BinaryHeap !( Point!d[], (a, b) => distance(a, p) < distance(b, p) ) (storage);
}

// unittest // makePriorityQueue()
// {
//     auto points = [ Point!2([1,2]), Point!2([3,1]), Point!2([2,3]) ];
//     auto pq = makePriorityQueue( Point!2([0,0]) );
//     foreach ( p ; points )
//     {
//         pq.insert(p);
//     }

//     /* It's the farthest away */
//     assert(pq.front == Point!2([2,3]));

//     /* Remove (2,3) */
//     pq.popFront;

//     /* Use release to get the array out of the pq */
//     assert( pq.release == [ Point!2([3,1]), Point!2([1,2])] ); // The farthest is still furthest
// }

/******************************************************************************
 * \brief
 *
 * Reorders points so that the closest to p comes first, and the farthest from p is last
 *****************************************************************************/
void sortByDistance(size_t d)(Point!d[] points, Point!d p)
{
    points.sort !( (a, b) => distance(a, p) < distance(b, p) );
}

/******************************************************************************
 * \brief
 *
 * Similar to sort.  Array will be reordered so the k closest to p will come first
 *
 * There are no guarantees of order though, so they won't be sorted, and the rest won't be sorted
 *
 * This will be a little bit faster than sort if you don't care about the ordering for part of the list
 *****************************************************************************/
void topNByDistance (size_t d) (Point !d[] points, Point !d p, int k)
{
    points.topN!( (a, b) => distance(a, p) < distance(b, p) ) (k);
}

/******************************************************************************
 * \brief
 *
 * Get n points with coordinates uniformly distributed between 0 and 1
 *
 * When d == 2, this is points in the "unit squre", d == 3 -> unit cube, etc
 *****************************************************************************/
Point !d [] getUniformPoints (size_t d) (size_t n)
{
    import std.random : uniform01;

    auto res = new Point!d[n];

    foreach ( ref p ; res )
    {
        foreach ( i ; 0..d )
        {
            p[i] = uniform01 !float;
        }
    }

    return res;
}

/******************************************************************************
 * \brief
 *
 * Get points with coordinates that come from a normal distribution with mean = 0
 * variance = 1.  Unlike the uniform points, these will NOT be evenly spread out.\
 *
 * There will be more points closer to the origin than further away.
 *
 * Also note, there is not bound on how far away the points may be from the origin
 *
 * The further from the origin, the lower the probability of sampling them, but
 * you could get points very far away if you're "lucky"
 *****************************************************************************/
Point!d[] getGaussianPoints (size_t d) (size_t n)
{
    import std.mathspecial : normalDistributionInverse;

    return getUniformPoints!d(n).map!
    ( 
        function(Point!d x)
        {
            Point !d res;

            foreach (i ; 0..d)
            {
                res[i] = normalDistributionInverse(x[i]);
            }

            return res;
        }
    ).
    array;
}

// unittest // common.getGaussianPoints()
// {
//     /* 1000 2D points in the [0,1] square */
//     auto uPoints = getUniformPoints!2(1000);
//     auto uBounds = boundingBox(uPoints);

//     /* They should all be within the unit square */
//     assert( uBounds.min[0] >= 0 );
//     assert( uBounds.min[1] >= 0 );
//     assert( uBounds.max[0] <= 1 );
//     assert( uBounds.max[1] <= 1 );

//     auto gPoints = getGaussianPoints !3 (10000);

//     /* No guarantees here... */
//     writeln( "Gaussian points bounding box: ", boundingBox(gPoints) );
// }
