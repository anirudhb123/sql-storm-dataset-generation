WITH RECURSIVE RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
HighValueLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_shipdate,
        l.l_returnflag,
        CASE 
            WHEN l.l_discount > 0.1 THEN 'High Discount'
            ELSE 'Standard Discount'
        END AS DiscountType
    FROM 
        lineitem l
    WHERE 
        l.l_quantity > (SELECT AVG(l2.l_quantity) FROM lineitem l2)
),
HighValueProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS TotalRevenue
    FROM 
        part p
    LEFT JOIN 
        HighValueLineItems l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TotalHighValueProducts AS (
    SELECT 
        SUM(TotalRevenue) AS OverallRevenue
    FROM 
        HighValueProducts
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS Region,
    n.n_name AS Nation,
    COALESCE(sp.r_suppname, 'No Supplier') AS SupplierName,
    hvp.p_name AS ProductName,
    hvp.TotalRevenue,
    cho.TotalOrders,
    cho.TotalSpent,
    thvp.OverallRevenue
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers sp ON n.n_nationkey = sp.s_nationkey AND sp.rank = 1
LEFT JOIN 
    HighValueProducts hvp ON hvp.TotalRevenue > (SELECT AVG(TotalRevenue) FROM HighValueProducts)
LEFT JOIN 
    CustomerOrders cho ON cho.TotalSpent > (SELECT AVG(TotalSpent) FROM CustomerOrders)
CROSS JOIN 
    TotalHighValueProducts thvp
ORDER BY 
    hvp.TotalRevenue DESC NULLS LAST;
