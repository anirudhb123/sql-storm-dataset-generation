WITH RECURSIVE supplier_chain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sc.level + 1
    FROM supplier s
    JOIN supplier_chain sc ON s.s_nationkey = sc.s_nationkey
    WHERE s.s_acctbal > 0 AND sc.level < 5
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o 
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice * 0.9) FROM orders o2)
),
high_value_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice, 
           (SELECT SUM(ps.ps_supplycost) 
            FROM partsupp ps 
            WHERE ps.ps_partkey = p.p_partkey) AS total_supply_cost
    FROM part p 
    WHERE p.p_size IN (SELECT DISTINCT ps.ps_availqty 
                       FROM partsupp ps 
                       WHERE ps.ps_supplycost > 100)
),
order_line_items AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_extendedprice, 
           CASE 
               WHEN l.l_discount > 0.2 THEN 'High Discount'
               ELSE 'Standard'
           END AS discount_category
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    COALESCE(SUM(hp.total_supply_cost), 0) AS total_supply_cost,
    MAX(o.o_totalprice) OVER () AS max_order_price,
    SUM(CASE WHEN o.disc_category = 'High Discount' THEN o.l_extendedprice ELSE 0 END) AS total_high_discount_price,
    COUNT(DISTINCT c.c_custkey) FILTER (WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal < 500) AS low_balance_customers 
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier_chain s ON n.n_nationkey = s.s_nationkey
LEFT JOIN high_value_parts hp ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = hp.p_partkey LIMIT 1)
LEFT JOIN ranked_orders o ON o.o_orderkey = (SELECT l.l_orderkey FROM order_line_items l WHERE l.l_partkey = hp.p_partkey ORDER BY l.l_extendedprice DESC LIMIT 1)
JOIN customer c ON c.c_nationkey = n.n_nationkey
GROUP BY r.r_name
HAVING SUM(COALESCE(o.o_totalprice, 0)) > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderdate >= '2023-01-01')
ORDER BY supplier_count DESC, total_supply_cost ASC;
