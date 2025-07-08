WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN order_hierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderdate > oh.o_orderdate
),
supplier_aggregation AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 1000
    GROUP BY ps.ps_partkey
),
region_balance AS (
    SELECT n.n_regionkey, SUM(c.c_acctbal) AS total_balance
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_regionkey
)
SELECT 
    p.p_name,
    p.p_brand,
    ra.total_balance,
    sa.total_cost,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    region_balance ra ON ra.n_regionkey = s.s_nationkey
JOIN 
    supplier_aggregation sa ON sa.ps_partkey = p.p_partkey
WHERE 
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31' 
    AND l.l_returnflag = 'N'
GROUP BY 
    p.p_name, p.p_brand, ra.total_balance, sa.total_cost
HAVING 
    AVG(l.l_extendedprice * (1 - l.l_discount)) > 100
ORDER BY 
    total_balance DESC, order_count DESC
LIMIT 50;