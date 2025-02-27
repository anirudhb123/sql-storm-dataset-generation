WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        o.o_orderdate,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_mktsegment
),
CustomerRanking AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        DENSE_RANK() OVER (ORDER BY SUM(os.TotalRevenue) DESC) AS CustomerRank
    FROM 
        customer c
    LEFT JOIN 
        OrderSummary os ON c.c_custkey = os.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    p.p_name,
    rs.s_name AS TopSupplier,
    os.TotalRevenue,
    cr.CustomerRank
FROM 
    part p
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.s_suppkey AND rs.SupplierRank = 1
LEFT JOIN 
    OrderSummary os ON os.o_orderkey IN (
        SELECT 
            o.o_orderkey 
        FROM 
            orders o
        WHERE 
            o.o_orderstatus IN ('O', 'F')
    )
LEFT JOIN 
    CustomerRanking cr ON cr.c_custkey = os.o_orderkey
WHERE 
    p.p_size > 15
ORDER BY 
    os.TotalRevenue DESC, cr.CustomerRank;
