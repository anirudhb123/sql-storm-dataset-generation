WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplyRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS TotalOrderValue,
        COALESCE(SUM(l.l_discount * l.l_extendedprice), 0) AS TotalDiscount
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.TotalOrderValue, 
        c.TotalDiscount
    FROM 
        CustomerOrders c
    WHERE 
        c.TotalOrderValue > 100000 AND c.TotalDiscount <= 5000
),
RegionNation AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        n.n_nationkey, 
        n.n_name
    FROM 
        region r
    JOIN 
        nation n ON n.n_regionkey = r.r_regionkey
)
SELECT 
    rn.r_name AS Region,
    COUNT(DISTINCT hvc.c_custkey) AS HighValueCustomerCount,
    AVG(hvc.TotalOrderValue) AS AvgOrderValue,
    SUM(hvc.TotalDiscount) AS TotalDiscountGiven,
    ss.s_name AS SupplierName,
    MAX(rs.TotalSupplyCost) AS MaxSupplierCost
FROM 
    HighValueCustomers hvc
JOIN 
    RegionNation rn ON hvc.c_custkey = 1 OR rn.n_nationkey = (SELECT n_nationkey FROM customer WHERE c_custkey = hvc.c_custkey)  -- Correlated subquery for nation
LEFT JOIN 
    RankedSuppliers rs ON rs.SupplyRank <= 5
LEFT JOIN 
    supplier ss ON ss.s_nationkey = rn.n_nationkey
GROUP BY 
    rn.r_name, ss.s_name
HAVING 
    COUNT(DISTINCT hvc.c_custkey) > 0
ORDER BY 
    AvgOrderValue DESC, TotalDiscountGiven;
