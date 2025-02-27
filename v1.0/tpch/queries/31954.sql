
WITH RECURSIVE PriceHierarchy AS (
    SELECT 
        p_partkey,
        p_name,
        p_brand,
        1 AS level,
        p_retailprice AS price
    FROM 
        part
    WHERE
        p_retailprice > 100.00

    UNION ALL

    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        ph.level + 1,
        ph.price * 0.9 AS price
    FROM 
        part p
    JOIN 
        PriceHierarchy ph ON p.p_partkey = ph.p_partkey
    WHERE 
        ph.level < 5
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= '1997-01-01'
)
SELECT 
    n.n_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END), 0) AS return_revenue,
    AVG(ph.price) AS avg_price,
    COUNT(DISTINCT co.o_orderkey) AS distinct_orders
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    PriceHierarchy ph ON l.l_partkey = ph.p_partkey
LEFT JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND 
    l.l_shipdate < '1998-01-01' AND 
    (l.l_discount > 0.05 OR ph.price IS NOT NULL)
GROUP BY 
    n.n_name, ph.price
ORDER BY 
    total_revenue DESC
LIMIT 10;
