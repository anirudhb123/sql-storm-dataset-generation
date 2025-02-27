WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        DENSE_RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplyRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS CustRank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS LineItemCount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    c.c_name AS CustomerName,
    s.s_name AS SupplierName,
    ps.ps_supplycost AS SupplyCost,
    os.TotalRevenue AS Revenue,
    COALESCE(r.TotalSupplyCost, 0) AS SupplierCost,
    (CASE 
        WHEN os.TotalRevenue > 10000 THEN 'High'
        WHEN os.TotalRevenue BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END) AS RevenueCategory
FROM 
    HighValueCustomers c
LEFT JOIN 
    OrderSummary os ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = os.o_orderkey LIMIT 1)
JOIN 
    RankedSuppliers r ON r.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = os.o_orderkey LIMIT 1) LIMIT 1)
WHERE 
    r.SupplyRank = 1
ORDER BY 
    c.c_name, s.s_name;
