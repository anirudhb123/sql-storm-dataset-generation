WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS level
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'

    UNION ALL

    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        co.level + 1
    FROM 
        CustomerOrders co
    JOIN 
        orders o ON co.o_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND co.level < 10
),
AggOrderAmount AS (
    SELECT 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        CustomerOrders o
    JOIN 
        customer c ON o.c_custkey = c.c_custkey
    GROUP BY 
        c.c_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL 
        AND p.p_size > 0
)
SELECT 
    r.r_name,
    n.n_name,
    COALESCE(a.total_spent, 0) AS total_spent,
    pp.p_name,
    pp.p_retailprice,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    AggOrderAmount a ON a.c_name LIKE '%' || n.n_name || '%'
LEFT JOIN 
    PartDetails pp ON pp.rn <= 5
GROUP BY 
    r.r_name, n.n_name, a.total_spent, pp.p_name, pp.p_retailprice
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY 
    total_spent DESC, r.r_name, n.n_name;
