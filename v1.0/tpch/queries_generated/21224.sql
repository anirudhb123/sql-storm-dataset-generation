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
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS CustomerRank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_acctbal IS NOT NULL)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalOrderValue,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    r.r_name,
    COALESCE(SupplierInfo.s_name, 'No Supplier') AS SupplierName,
    COALESCE(CustomerInfo.c_name, 'No Customer') AS CustomerName,
    MAX(OrderInfo.TotalOrderValue) AS MaxOrderValue,
    COUNT(DISTINCT CustomerInfo.c_custkey) AS UniqueCustomerCount
FROM 
    region r
LEFT JOIN 
    (SELECT ns.n_regionkey, ns.n_name, ns.n_nationkey FROM nation ns) AS NationInfo ON r.r_regionkey = NationInfo.n_regionkey 
LEFT JOIN 
    (SELECT * FROM RankedSuppliers WHERE SupplyRank = 1) AS SupplierInfo ON NationInfo.n_nationkey = SupplierInfo.s_nationkey
LEFT JOIN 
    (SELECT * FROM HighValueCustomers WHERE CustomerRank <= 5) AS CustomerInfo ON CustomerInfo.c_custkey = (SELECT TOP 1 o.o_custkey FROM orders o WHERE o.o_orderkey = OrderInfo.o_orderkey ORDER BY o.o_orderkey DESC)
JOIN 
    (SELECT * FROM OrderDetails) AS OrderInfo ON OrderInfo.o_orderkey = (SELECT TOP 1 l.l_orderkey FROM lineitem l ORDER BY l.l_orderkey DESC)
GROUP BY 
    r.r_name, SupplierInfo.s_name, CustomerInfo.c_name
HAVING 
    MAX(OrderInfo.TotalOrderValue) > 10000 OR SupplierInfo.s_name IS NULL
ORDER BY 
    r.r_name, MaxOrderValue DESC;
