WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT p.p_partkey) AS UniquePartsSupplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS OrderValue,
        COUNT(l.l_orderkey) AS TotalLineItems,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(od.OrderValue) AS TotalSpent
    FROM 
        customer c
    JOIN 
        OrderDetails od ON c.c_custkey = od.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(od.OrderValue) > 10000
)
SELECT 
    t.c_custkey,
    t.c_name,
    COALESCE(ts.UniquePartsSupplied, 0) AS UniquePartsSupplied,
    COALESCE(t.TotalSpent, 0) AS TotalSpent,
    CASE 
        WHEN ts.TotalSupplyCost IS NULL THEN 'No Supply Cost'
        ELSE CONCAT('Total Supply Cost: $', FORMAT(ts.TotalSupplyCost, 2))
    END AS SupplyInfo
FROM 
    TopCustomers t
LEFT JOIN 
    SupplierStats ts ON t.c_custkey = ts.s_suppkey
ORDER BY 
    t.TotalSpent DESC, t.c_name;
