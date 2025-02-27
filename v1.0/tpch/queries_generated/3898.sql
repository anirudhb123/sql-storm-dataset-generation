WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_type,
        (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 10
),
CustomerWithTotalRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(fo.total_revenue) AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        FilteredOrders fo ON c.c_custkey = fo.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    c.c_name,
    s.s_name,
    sp.p_type,
    SUM(sp.ps_availqty) AS total_available_quantity,
    AVG(sp.profit_margin) AS average_profit_margin,
    ct.total_revenue
FROM 
    SupplierParts sp
JOIN 
    RankedSuppliers s ON sp.ps_suppkey = s.s_suppkey
LEFT JOIN 
    CustomerWithTotalRevenue ct ON ct.total_revenue IS NOT NULL
WHERE 
    s.rnk = 1
GROUP BY 
    c.c_name, s.s_name, sp.p_type, ct.total_revenue
HAVING 
    SUM(sp.ps_availqty) > 1000
ORDER BY 
    average_profit_margin DESC, total_available_quantity ASC;
