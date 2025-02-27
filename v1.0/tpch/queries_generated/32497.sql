WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.n_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.n_nationkey, h.level + 1
    FROM supplier s
    JOIN SupplierHierarchy h ON s.n_nationkey = h.n_nationkey
    WHERE h.level < 2
), SubqueryMaxPrice AS (
    SELECT ps_partkey, MAX(ps_supplycost) AS max_price
    FROM partsupp
    GROUP BY ps_partkey
), LineItemAnalysis AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(*) AS total_items,
           AVG(l.l_discount) AS average_discount
    FROM lineitem l
    WHERE l.l_shipdate < CURRENT_DATE - INTERVAL '2 days'
    GROUP BY l.l_orderkey
), TopLineItems AS (
    SELECT l_orderkey, net_revenue, total_items, average_discount,
           ROW_NUMBER() OVER (ORDER BY net_revenue DESC) AS rn
    FROM LineItemAnalysis
), CustomerOrderCounts AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING COUNT(o.o_orderkey) > 5
)
SELECT 
    p.p_partkey,
    p.p_name,
    sh.s_name AS supplier_name,
    rp.r_name AS region_name,
    lm.l_orderkey,
    lm.net_revenue,
    lm.total_items,
    lm.average_discount,
    cc.order_count,
    ps.max_price
FROM part p
LEFT JOIN supplier sh ON sh.s_suppkey IN (SELECT ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
LEFT JOIN region rp ON sh.n_nationkey = rp.r_regionkey
JOIN TopLineItems lm ON lm.l_orderkey IN (SELECT l_orderkey FROM lineitem WHERE l_partkey = p.p_partkey)
JOIN CustomerOrderCounts cc ON cc.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = lm.l_orderkey)
LEFT JOIN SubqueryMaxPrice ps ON ps.ps_partkey = p.p_partkey
WHERE p.p_size BETWEEN 10 AND 20
  AND ps.max_price IS NOT NULL
ORDER BY lm.net_revenue DESC, p.p_partkey ASC;
