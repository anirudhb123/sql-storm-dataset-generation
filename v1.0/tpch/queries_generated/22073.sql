WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
), 
suppliers_with_part_count AS (
    SELECT s.s_suppkey, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
), 
customer_order_details AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey
), 
lineitem_analysis AS (
    SELECT l.l_orderkey, 
           SUM(CASE WHEN l.l_discount > 0.10 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS adjusted_price
    FROM lineitem l
    WHERE l.l_shipdate < CURRENT_DATE
    GROUP BY l.l_orderkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    AVG(co.total_spent) AS avg_customer_spent,
    MAX(sp.part_count) AS max_supplied_parts,
    SUM(COALESCE(la.adjusted_price, 0)) AS total_adjusted_price
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN suppliers_with_part_count sp ON n.n_nationkey = (SELECT s.n_nationkey FROM supplier s WHERE s.s_suppkey = sp.s_suppkey)
JOIN customer_order_details co ON n.n_nationkey = co.c_custkey
LEFT JOIN lineitem_analysis la ON la.l_orderkey = co.c_custkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
WHERE n.n_name IS NOT NULL
GROUP BY r.r_name, n.n_name, s.s_name, c.c_name
HAVING COUNT(DISTINCT co.o_orderkey) > 5
ORDER BY region_name DESC, avg_customer_spent DESC
OFFSET 5 ROWS 
FETCH NEXT 10 ROWS ONLY;
