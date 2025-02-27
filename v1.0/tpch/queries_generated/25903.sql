WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_name LIKE '%' || 'steel' || '%'
),
ActiveOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalPrice,
        COUNT(DISTINCT l.l_orderkey) AS ItemCount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate >= CURRENT_DATE - INTERVAL '30 day'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    r.s_name AS SupplierName,
    r.s_acctbal AS AccountBalance,
    a.o_orderkey AS OrderKey,
    a.ItemCount AS NumberOfItems,
    CAST(a.TotalPrice AS DECIMAL(12, 2)) AS TotalOrderPrice
FROM 
    RankedSuppliers r
JOIN 
    ActiveOrders a ON r.SupplierRank = 1
ORDER BY 
    r.AccountBalance DESC, a.TotalOrderPrice DESC
LIMIT 10;
