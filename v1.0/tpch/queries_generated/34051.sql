WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS depth
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)   -- Filter suppliers with above average account balance

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey -- Join on nationkey to create hierarchy
)
SELECT
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT p.p_name) AS product_list,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS sales_rank
FROM lineitem li
JOIN orders o ON li.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN supplier s ON li.l_suppkey = s.s_suppkey
JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey AND ps.ps_partkey = li.l_partkey
JOIN part p ON p.p_partkey = li.l_partkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT OUTER JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey -- outer join to include suppliers in hierarchy
WHERE
    (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL) -- Potential NULL logic with order status
    AND li.l_shipdate >= '2023-01-01' -- Filter for recent orders
GROUP BY n.n_name
HAVING AVG(ps.ps_supplycost) < (SELECT AVG(ps.ps_supplycost) FROM partsupp)  -- Compare avg supply cost across parts
ORDER BY total_sales DESC;
