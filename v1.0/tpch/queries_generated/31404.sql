WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_clerk, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_clerk, oh.level + 1
    FROM orders o
    INNER JOIN order_hierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_totalprice > 1000
),
supplier_summary AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
lineitem_analysis AS (
    SELECT l.l_partkey, SUM(l.l_quantity) AS total_quantity, AVG(l.l_discount) AS avg_discount, 
           SUM(l.l_extendedprice) AS total_extended_price,
           ROW_NUMBER() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_extendedprice) DESC) AS rnk
    FROM lineitem l
    WHERE l.l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY l.l_partkey
)

SELECT 
    p.p_name,
    ps.ps_availqty,
    ss.total_supply_cost,
    la.total_quantity,
    la.avg_discount,
    oh.o_orderkey,
    oh.o_orderdate
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier_summary ss ON ps.ps_suppkey = ss.s_suppkey
LEFT JOIN lineitem_analysis la ON p.p_partkey = la.l_partkey
LEFT JOIN order_hierarchy oh ON oh.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal IS NOT NULL))
WHERE p.p_retailprice IS NOT NULL
AND (ps.ps_availqty > 0 OR la.total_quantity IS NOT NULL)
ORDER BY la.total_quantity DESC NULLS LAST, ss.total_supply_cost DESC;
