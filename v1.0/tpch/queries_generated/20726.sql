WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = c.c_nationkey)
), 
Suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_discount,
        CASE 
            WHEN l.l_discount = 0 THEN 'No Discount'
            ELSE 'Discount Applied'
        END AS DiscountStatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY l.l_orderkey) AS NetPrice
    FROM 
        lineitem l
), 
OrderSummary AS (
    SELECT 
        co.c_custkey,
        s.s_name,
        SUM(l.NetPrice) AS TotalNetSales
    FROM 
        CustomerOrders co
    JOIN 
        LineItemAnalysis l ON co.o_orderkey = l.l_orderkey
    LEFT JOIN 
        Suppliers s ON s.TotalSupplyCost > 1000
    GROUP BY 
        co.c_custkey, s.s_name
)
SELECT 
    co.c_custkey,
    co.c_name,
    os.s_name,
    os.TotalNetSales,
    COALESCE(os.TotalNetSales, 0) AS SafeguardNetSales,
    CASE 
        WHEN os.TotalNetSales IS NULL THEN 'No Sales'
        WHEN os.TotalNetSales > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS CustomerValue
FROM 
    CustomerOrders co
LEFT JOIN 
    OrderSummary os ON co.c_custkey = os.c_custkey
WHERE 
    co.OrderRank = 1
ORDER BY 
    co.c_custkey, CustomerValue DESC;
