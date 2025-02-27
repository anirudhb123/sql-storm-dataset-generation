WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
), ExpensiveParts AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
), SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(ps.ps_partkey) AS PartsSupplied
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), LastOrderDetails AS (
    SELECT 
        co.c_custkey, 
        co.o_orderkey, 
        co.o_orderdate, 
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS TotalLineItemValue
    FROM 
        CustomerOrders co
    LEFT JOIN 
        lineitem l ON co.o_orderkey = l.l_orderkey
    WHERE 
        co.OrderRank = 1
    GROUP BY 
        co.c_custkey, co.o_orderkey, co.o_orderdate
)
SELECT 
    n.n_name AS Nation, 
    s.s_name AS SupplierName, 
    COALESCE(SI.PartsSupplied, 0) AS PartsSuppliedCount,
    COALESCE(L.TotalLineItemValue, 0) AS LastOrderValue,
    (SELECT COUNT(DISTINCT c.c_custkey) FROM customer c WHERE c.c_nationkey = n.n_nationkey) AS CustomerCount
FROM 
    nation n
LEFT JOIN 
    SupplierInfo SI ON n.n_nationkey = (SELECT n_nationkey FROM supplier s WHERE s.s_suppkey = SI.s_suppkey LIMIT 1)
LEFT JOIN 
    LastOrderDetails L ON L.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
WHERE 
    s.s_acctbal IS NOT NULL
ORDER BY 
    n.n_name, s.s_name;
