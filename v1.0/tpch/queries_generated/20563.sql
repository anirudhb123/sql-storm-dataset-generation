WITH RECURSIVE SalesCTE AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
      AND l.l_shipdate < CURRENT_DATE
    GROUP BY o.o_orderkey

    UNION ALL

    SELECT s.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders s
    JOIN lineitem l ON s.o_orderkey = l.l_orderkey
    JOIN SalesCTE sc ON s.o_orderkey = sc.o_orderkey
    WHERE l.l_returnflag = 'R'
    GROUP BY s.o_orderkey
),
SupplierSummary AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey
),
TopNations AS (
    SELECT ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.c_custkey) DESC) AS rn,
           n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_name
),
CombinedResults AS (
    SELECT p.p_name, COALESCE(SUM(ss.total_supply_cost * 1.2), 0) AS total_cost,
           COALESCE(MAX(ss.unique_parts), 0) AS max_parts,
           t.n_name AS top_nation, COALESCE(s.total_sales, 0) AS total_order_sales
    FROM part p
    LEFT JOIN SupplierSummary ss ON p.p_partkey = ss.s_suppkey
    LEFT JOIN TopNations t ON t.rn = 1
    LEFT JOIN SalesCTE s ON p.p_partkey = s.o_orderkey
    WHERE p.p_retailprice <= (
        SELECT AVG(p2.p_retailprice)
        FROM part p2
        WHERE p2.p_size > 10
    ) OR p.p_comment LIKE '%Fragile%'
    GROUP BY p.p_name, t.n_name
)
SELECT c.*, CASE WHEN c.total_cost > 10000 THEN 'High' ELSE 'Low' END AS cost_category
FROM CombinedResults c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.o_orderkey = c.total_order_sales
      AND o.o_totalprice < 50
)
ORDER BY c.total_cost DESC;
