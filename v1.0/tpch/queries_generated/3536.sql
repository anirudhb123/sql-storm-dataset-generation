WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        c.c_acctbal,
        NTH_VALUE(c.c_mktsegment, 1) OVER (ORDER BY c.c_acctbal DESC) AS TopSegment
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        l.l_partkey,
        l.l_discount,
        l.l_returnflag,
        l.l_quantity * (l.l_extendedprice * (1 - l.l_discount)) AS NetPrice
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
),
AggregatedOrderData AS (
    SELECT 
        od.o_orderkey,
        SUM(od.NetPrice) AS TotalNetPrice,
        COUNT(*) AS TotalItems
    FROM 
        OrderDetails od
    GROUP BY 
        od.o_orderkey
)

SELECT 
    n.n_name AS NationName,
    COUNT(DISTINCT rv.c_custkey) AS HighValueCustomerCount,
    SUM(a.TotalNetPrice) AS TotalSales,
    AVG(c.c_acctbal) AS AverageCustomerBalance
FROM 
    RankedSuppliers rv
LEFT JOIN 
    HighValueCustomers c ON rv.s_nationkey = c.c_nationkey
LEFT JOIN 
    AggregatedOrderData a ON a.o_orderkey IN (SELECT l_orderkey FROM lineitem WHERE l_suppkey = rv.s_suppkey)
JOIN 
    nation n ON rv.s_nationkey = n.n_nationkey
WHERE 
    rv.rank <= 5
GROUP BY 
    n.n_name
HAVING 
    SUM(a.TotalNetPrice) > 1000000 OR COUNT(DISTINCT rv.c_custkey) > 10
ORDER BY 
    TotalSales DESC;
