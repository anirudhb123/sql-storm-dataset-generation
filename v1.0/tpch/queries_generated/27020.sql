WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_supplycost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighSupplySuppliers AS (
    SELECT 
        s.s_name,
        p.p_name,
        MIN(ps.ps_supplycost) AS min_supplycost
    FROM 
        RankedSuppliers rss
    JOIN 
        supplier s ON rss.s_suppkey = s.s_suppkey
    JOIN 
        partsupp ps ON rss.ps_supplycost = ps.ps_supplycost
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        rss.rank <= 3
    GROUP BY 
        s.s_name, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY 
        c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    hss.s_name,
    hss.p_name,
    coh.c_name,
    coh.o_orderdate,
    coh.total_revenue
FROM 
    HighSupplySuppliers hss
JOIN 
    CustomerOrders coh ON hss.p_name LIKE '%' || SUBSTRING(coh.c_name FROM 1 FOR 3) || '%'
ORDER BY 
    hss.p_name, coh.total_revenue DESC;
