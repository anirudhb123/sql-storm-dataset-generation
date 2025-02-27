WITH RECURSIVE order_hierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS order_level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    UNION ALL
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.order_level + 1
    FROM 
        orders o
    JOIN 
        order_hierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE 
        oh.order_level < 5
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    p.p_retailprice,
    CONCAT(n.n_name, ' - ', r.r_name) AS location,
    (SELECT 
         SUM(l.l_extendedprice * (1 - l.l_discount)) 
     FROM 
         lineitem l 
     WHERE 
         l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT cs.c_custkey FROM customer_summary cs WHERE cs.total_spent > 10000))
    ) AS total_revenue,
    cs.total_spent,
    RANK() OVER (PARTITION BY p.p_brand ORDER BY cs.total_spent DESC) AS brand_rank
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    customer_summary cs ON cs.order_count > 3
WHERE 
    p.p_retailprice > 50.00
    AND ps.ps_availqty IS NOT NULL
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 100.00)
    AND EXISTS (SELECT 1 FROM lineitem l WHERE l.l_shipdate > '2023-01-01')
ORDER BY 
    total_revenue DESC
LIMIT 10;
