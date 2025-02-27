WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_container
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(c.c_acctbal) AS total_acctbal
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        customer c ON s.s_suppkey = c.c_nationkey
    GROUP BY 
        n.n_name
    ORDER BY 
        total_acctbal DESC
    LIMIT 5
),
ActiveOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        oi.l_partkey,
        SUM(oi.l_quantity) AS total_quantity
    FROM 
        orders o
    JOIN 
        lineitem oi ON o.o_orderkey = oi.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, oi.l_partkey
)
SELECT 
    r.region_name,
    rp.p_name,
    rp.total_availqty,
    rp.avg_supplycost,
    ao.total_quantity,
    ao.o_totalprice
FROM 
    RankedParts rp
JOIN 
    TopNations tn ON rp.p_brand = tn.n_name
JOIN 
    ActiveOrders ao ON rp.p_partkey = ao.l_partkey
JOIN 
    region r ON tn.n_regionkey = r.r_regionkey
WHERE 
    ao.total_quantity > 100
ORDER BY 
    rp.avg_supplycost DESC, ao.o_totalprice ASC
LIMIT 10;
