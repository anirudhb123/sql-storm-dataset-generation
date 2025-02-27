WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate) as order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
), RankedLineItems AS (
    SELECT li.l_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM lineitem li
    GROUP BY li.l_orderkey
), SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count,
           SUM(ps.ps_supplycost) AS total_supply_cost,
           SUM(CASE WHEN li.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returns_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    GROUP BY s.s_suppkey, s.s_name
), NationSales AS (
    SELECT n.n_nationkey, n.n_name, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY n.n_nationkey, n.n_name
), CombinedResults AS (
    SELECT co.c_custkey, co.c_name, SUM(rl.total_revenue) AS overall_revenue,
           ns.total_sales, sp.part_count, sp.total_supply_cost, sp.returns_count
    FROM CustomerOrders co
    LEFT JOIN RankedLineItems rl ON co.o_orderkey = rl.l_orderkey
    LEFT JOIN NationSales ns ON co.c_custkey IN (
        SELECT c.c_custkey FROM customer c
        WHERE c.c_nationkey = co.c_custkey
    )
    LEFT JOIN SupplierPerformance sp ON sp.part_count > 0
    WHERE ns.total_sales IS NOT NULL
    AND rl.total_revenue IS NOT NULL
    GROUP BY co.c_custkey, co.c_name, ns.total_sales, sp.part_count, sp.total_supply_cost, sp.returns_count
)
SELECT *, current_timestamp AS benchmark_timestamp
FROM CombinedResults
WHERE overall_revenue > 1000
ORDER BY overall_revenue DESC;
