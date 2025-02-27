WITH RECURSIVE supplier_cust AS (
    SELECT s.s_suppkey, s.s_name, c.c_custkey, c.c_name, c.c_mktsegment
    FROM supplier s
    LEFT JOIN customer c ON s.s_nationkey = c.c_nationkey
    WHERE c.c_custkey IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, c.c_custkey, c.c_name, c.c_mktsegment
    FROM supplier_cust sc
    JOIN supplier s ON sc.s_suppkey = s.s_suppkey
    JOIN customer c ON s.s_nationkey = c.c_nationkey
)
SELECT 
    p.p_name,
    COUNT(DISTINCT cu.c_custkey) AS customer_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN 'Returned' ELSE 'Not Returned' END) AS return_status,
    RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice) DESC) AS regional_rank,
    STRING_AGG(s.s_name, ', ') FILTER (WHERE c.c_mktsegment = 'BUILDING') AS building_suppliers,
    COALESCE(MAX(o.o_totalprice), 0) AS max_order_price,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY COUNT(o.o_orderkey) DESC) AS order_rank
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer cu ON cu.c_custkey = o.o_custkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice BETWEEN 10.00 AND 100.00
AND l.l_shipdate > (SELECT MAX(l_shipdate) FROM lineitem WHERE l_returnflag = 'N')
GROUP BY p.p_name, r.r_name
HAVING COUNT(DISTINCT cu.c_custkey) > 5
ORDER BY regional_rank, customer_count DESC;
