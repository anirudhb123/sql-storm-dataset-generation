WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        p.p_partkey, 
        p.p_name, 
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), FilteredCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_nationkey 
    FROM 
        customer c 
    WHERE 
        c.c_acctbal > 1000 AND c.c_mktsegment = 'BUILDING'
), HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice 
    FROM 
        orders o 
    WHERE 
        o.o_totalprice > 5000
)
SELECT 
    fc.c_custkey, 
    fc.c_name, 
    COUNT(DISTINCT ho.o_orderkey) AS HighValueOrderCount, 
    SUM(rs.s_acctbal) AS TotalAccountBalance,
    AVG(rs.s_acctbal) AS AvgSupplierBalance,
    STRING_AGG(CONCAT(rs.s_name, ' (', rs.p_name, ')'), ', ') AS SupplierProductList
FROM 
    FilteredCustomers fc 
JOIN 
    HighValueOrders ho ON fc.c_custkey = ho.o_custkey 
JOIN 
    RankedSuppliers rs ON rs.rank = 1 
GROUP BY 
    fc.c_custkey, 
    fc.c_name 
ORDER BY 
    TotalAccountBalance DESC, 
    HighValueOrderCount DESC 
LIMIT 100;
