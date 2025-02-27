WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_country ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS RankInCountry
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_country
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
OrderInsights AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS OrderRevenue,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS LineItemCount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
)
SELECT 
    ns.n_name AS NationName,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    SUM(oi.OrderRevenue) AS TotalRevenue,
    AVG(cs.c_acctbal) AS AvgCustomerBalance
FROM 
    nation ns
LEFT JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    HighValueCustomers cs ON o.o_custkey = cs.c_custkey
LEFT JOIN 
    OrderInsights oi ON o.o_orderkey = oi.o_orderkey
WHERE 
    oi.OrderRevenue IS NOT NULL
GROUP BY 
    ns.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10 
    AND AVG(cs.c_acctbal) IS NOT NULL
ORDER BY 
    TotalRevenue DESC;
