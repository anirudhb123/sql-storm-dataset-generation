WITH RECURSIVE CTE_SupplierCost AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CTE_AverageOrderValue AS (
    SELECT 
        o.o_orderkey,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_order_value,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY o.o_orderkey
),
FINAL_RESULT AS (
    SELECT 
        r.r_name,
        COUNT(n.n_nationkey) AS nation_count,
        SUM(CASE WHEN sc.rank = 1 THEN sc.total_cost ELSE 0 END) AS max_supply_cost,
        AVG(a.avg_order_value) AS avg_order_per_customer,
        SUM(COALESCE(c.c_acctbal, 0) * (CASE WHEN c.c_mktsegment IS NULL THEN 0.5 ELSE 1 END)) AS adjusted_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN CTE_SupplierCost sc ON n.n_nationkey = sc.s_nationkey
    LEFT JOIN CTE_AverageOrderValue a ON a.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey))
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY r.r_name
)
SELECT 
    f.r_name,
    f.nation_count,
    f.max_supply_cost,
    f.avg_order_per_customer,
    f.adjusted_acctbal
FROM FINAL_RESULT f
WHERE f.nation_count > (SELECT AVG(nation_count) FROM FINAL_RESULT)
ORDER BY f.max_supply_cost DESC, f.avg_order_per_customer DESC;
