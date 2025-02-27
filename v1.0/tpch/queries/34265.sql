
WITH RECURSIVE partsupply_chain AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        1 AS level
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty > 0

    UNION ALL

    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty - 10 AS ps_availqty,
        ps.ps_supplycost,
        pc.level + 1
    FROM 
        partsupp ps
    INNER JOIN 
        partsupply_chain pc ON ps.ps_partkey = pc.ps_partkey
    WHERE 
        ps.ps_availqty - 10 > 0
),

customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
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
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COALESCE(r.r_name, 'Unknown') AS region_name,
    AVG(cs.total_spent) AS avg_customer_spending
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    customer_orders cs ON c.c_custkey = cs.c_custkey
WHERE 
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND l.l_returnflag = 'N'
GROUP BY 
    p.p_partkey, p.p_name, p.p_retailprice, r.r_name, cs.total_spent
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue DESC
LIMIT 10;
