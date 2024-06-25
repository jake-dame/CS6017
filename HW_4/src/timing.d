import common;

import std.conv : to;
import std.file;
import std.stdio;

void run_all_experiments ()
{
	const string file_name = "timing_data/timing_data.csv";

	File csv = File(file_name, "w");

	if (!csv.isOpen) {
		writeln("FILE DIDN'T OPEN");
		return;
	}

	csv.writeln("k,n,d,usecs,datastructure,test");

	csv.close();

	/* "DEFAULT" VALUES for every test */
	const int k = 10;
	const int n = 1000;
	const int d = 2;

	quadtree_vary_n  !d (k,    file_name, "QuadTree", "n");
	quadtree_vary_k  !d (n,    file_name, "QuadTree", "k");

	bucketing_vary_d    (k, n, file_name, "Bucketing", "d");
	bucketing_vary_n !d (k,    file_name, "Bucketing", "n");
	bucketing_vary_k !d (n,    file_name, "Bucketing", "k");

	kdtree_vary_d       (k, n, file_name, "KDTree", "d");
	kdtree_vary_n    !d (k,    file_name, "KDTree", "n");
	kdtree_vary_k    !d (n,    file_name, "KDTree", "k");
}

/**********************************************************************************************/

import quadtree;

void quadtree_vary_n (size_t d) (int k, string file_name, string data_structure, string test)
{
	File csv = File(file_name, "a");

	static
	foreach (n ; iota(100, 50000, 1000)) // n
	{
		{
			auto trainers = getGaussianPoints!d(n);
			auto testers  = getUniformPoints!d(100);

			auto quadtree = QuadTree(trainers);

			auto clock = StopWatch(AutoStart.no);

			clock.start;
			foreach(const ref qp ; testers)
			{
				auto res = quadtree.knn_query(qp, k);
			}
			clock.stop;

			writeln("quadtree n: ", n);

			csv.writeln(k, ',', n, ',', d, ',', clock.peek.total!"usecs", ',', data_structure, ',', test);
		}
	}

	csv.close();
}

void quadtree_vary_k (size_t d) (int n, string file_name, string data_structure, string test)
{
	File csv = File(file_name, "a");

	static
	foreach (k ; iota(10, 1000, 10)) // k
	{
		{
			auto trainers = getGaussianPoints!d(n);
			auto testers  = getUniformPoints!d(100);

			auto quadtree = QuadTree(trainers);

			auto clock = StopWatch(AutoStart.no);

			clock.start;
			foreach(const ref qp ; testers)
			{
				quadtree.knn_query(qp, k);
			}
			clock.stop;

			writeln("quadtree k: ", k);

			csv.writeln(k, ',', n, ',', d, ',', clock.peek.total!"usecs", ',', data_structure, ',', test);
		}
	}

	csv.close();
}

/**********************************************************************************************/

import bucketknn;

void bucketing_vary_d (int k, int n, string file_name, string data_structure, string test)
{
	File csv = File(file_name, "a");

	static
	foreach (d ; iota(1, 11)) // d
	{
		{
			auto trainers = getGaussianPoints!d(n);
			auto testers  = getUniformPoints!d(100);

			auto bucketknn = BucketKNN!d(trainers, 4);

			auto clock = StopWatch(AutoStart.no);

			clock.start;
			foreach(const ref qp ; testers)
			{
				bucketknn.knnQuery(qp, k);
			}
			clock.stop;

			writeln("bucketing d: ", d);

			csv.writeln(k, ',', n, ',', d, ',', clock.peek.total!"usecs", ',', data_structure, ',', test);
		}
	}

	csv.close();
}

void bucketing_vary_n (size_t d) (int k, string file_name, string data_structure, string test)
{
	File csv = File(file_name, "a");

	static
	foreach (n ; iota(100, 25000, 1000)) // n
	{
		{
			auto trainers = getGaussianPoints!d(n);
			auto testers  = getUniformPoints!d(100);

			auto bucketknn = BucketKNN!d(trainers, 6);

			auto clock = StopWatch(AutoStart.no);

			clock.start;
			foreach(const ref qp ; testers)
			{
				bucketknn.knnQuery(qp, k);
			}
			clock.stop;

			writeln("bucketing n: ", n);

			csv.writeln(k, ',', n, ',', d, ',', clock.peek.total!"usecs", ',', data_structure, ',', test);
		}
	}

	csv.close();
}

void bucketing_vary_k (size_t d) (int n, string file_name, string data_structure, string test)
{
	File csv = File(file_name, "a");

	static
	foreach (k ; iota(100, 1000, 50)) // k
	{
		{
			auto trainers = getGaussianPoints!d(n);
			auto testers  = getUniformPoints!d(100);

			auto bucketknn = BucketKNN!d(trainers, 4);

			auto clock = StopWatch(AutoStart.no);

			clock.start;
			foreach(const ref qp ; testers)
			{
				bucketknn.knnQuery(qp, k);
			}
			clock.stop;

			writeln("bucketing k: ", k);

			csv.writeln(k, ',', n, ',', d, ',', clock.peek.total!"usecs", ',', data_structure, ',', test);
		}
	}

	csv.close();
}

/**********************************************************************************************/

import kdtree;

void kdtree_vary_d (int k, int n, string file_name, string data_structure, string test)
{
	File csv = File(file_name, "a");

	static
	foreach (d ; iota(1, 11)) // d
	{
		{
			auto trainers = getGaussianPoints!d(n);
			auto testers  = getUniformPoints!d(100);

			auto kdtree = KDTree!d(trainers);

			auto clock = StopWatch(AutoStart.no);

			clock.start;
			foreach(const ref qp ; testers)
			{
				kdtree.knn_query(qp, k);
			}
			clock.stop;

			writeln("kdtree d: ", d);

			csv.writeln(k, ',', n, ',', d, ',', clock.peek.total!"usecs", ',', data_structure, ',', test);
		}
	}

	csv.close();
}

void kdtree_vary_n (size_t d) (int k, string file_name, string data_structure, string test)
{
	File csv = File(file_name, "a");

	static
	foreach (n ; iota(100, 50000, 1000)) // n
	{
		{
			auto trainers = getGaussianPoints!d(n);
			auto testers  = getUniformPoints!d(100);

			auto kdtree = KDTree!d(trainers);

			auto clock = StopWatch(AutoStart.no);

			clock.start;
			foreach(const ref qp ; testers)
			{
				kdtree.knn_query(qp, k);
			}
			clock.stop;

			writeln("kdtree n: ", n);

			csv.writeln(k, ',', n, ',', d, ',', clock.peek.total!"usecs", ',', data_structure, ',', test);
		}
	}

	csv.close();
}

void kdtree_vary_k (size_t d) (int n, string file_name, string data_structure, string test)
{
	File csv = File(file_name, "a");

	static
	foreach (k ; iota(100, 1000, 50)) // k
	{
		{
			auto trainers = getGaussianPoints!d(n);
			auto testers  = getUniformPoints!d(100);

			auto kdtree = KDTree!d(trainers);

			auto clock = StopWatch(AutoStart.no);

			clock.start;
			foreach(const ref qp ; testers)
			{
				kdtree.knn_query(qp, k);
			}
			clock.stop;

			writeln("kdtree k: ", k);

			csv.writeln(k, ',', n, ',', d, ',', clock.peek.total!"usecs", ',', data_structure, ',', test);
		}
	}

	csv.close();
}