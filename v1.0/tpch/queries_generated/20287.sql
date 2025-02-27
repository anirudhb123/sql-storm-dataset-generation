WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),

product_full_details AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           p.p_type, 
           COALESCE(CAST(NULLIF(l.l_returnflag, 'R') AS char(1)), '') AS returnflag,
           SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_revenue
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type, l.l_returnflag
),

orders_with_date AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           EXTRACT(YEAR FROM o.o_orderdate) AS order_year,
           ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate <= CURRENT_DATE AND o.o_orderstatus = 'O'
)

SELECT DISTINCT 
    r.r_name,
    n.n_name,
    s.s_name,
    COALESCE(MAX(pfd.total_revenue), 0) AS highest_revenue,
    COUNT(DISTINCT owd.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT p.p_name, ', ') AS product_names,
    SUM(CASE WHEN owd.order_rank <= 5 THEN owd.o_totalprice ELSE 0 END) AS top_order_total
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN product_full_details pfd ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = pfd.p_partkey)
LEFT JOIN orders_with_date owd ON owd.o_custkey = n.n_nationkey
WHERE owd.o_orderdate >= '2023-01-01'
GROUP BY r.r_name, n.n_name, s.s_name
HAVING SUM(COALESCE(s.s_acctbal, 0)) > 1000000
ORDER BY highest_revenue DESC, total_orders DESC
LIMIT 50
OFFSET (SELECT COUNT(*) FROM supplier_hierarchy) / 2;
