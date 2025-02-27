WITH RECURSIVE Supplier_Hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal >= 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN Supplier_Hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
Ranked_Orders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate > '2023-01-01'
),
Lineitem_Summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(*) AS line_count,
           COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM lineitem l
    GROUP BY l.l_orderkey
),
Top_Suppliers AS (
    SELECT s.s_suppkey, s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
)
SELECT 
    sh.s_name AS supplier_name,
    o.o_orderkey,
    ro.order_rank,
    ls.total_sales,
    CASE 
        WHEN ls.total_sales IS NULL THEN 'No Sales' 
        ELSE CONCAT('Total: ', ls.total_sales) 
    END AS sales_info,
    ts.total_supply_cost
FROM Supplier_Hierarchy sh
LEFT JOIN Ranked_Orders ro ON EXISTS (
    SELECT 1 FROM customer c 
    WHERE c.c_custkey = ro.o_orderkey
    AND c.c_nationkey = sh.s_nationkey
)
LEFT OUTER JOIN Lineitem_Summary ls ON ro.o_orderkey = ls.l_orderkey
FULL OUTER JOIN Top_Suppliers ts ON sh.s_suppkey = ts.s_suppkey
WHERE sh.level <= 3
ORDER BY sh.s_name, ro.o_orderkey;
