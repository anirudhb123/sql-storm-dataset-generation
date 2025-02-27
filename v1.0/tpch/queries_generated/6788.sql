WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueSuppliers AS (
    SELECT 
        *
    FROM 
        SupplierDetails
    WHERE 
        total_supplycost > 1000000
),
CombinedData AS (
    SELECT 
        R.o_orderkey,
        R.o_orderdate,
        R.o_totalprice,
        R.c_name,
        S.s_name,
        S.total_supplycost
    FROM 
        RankedOrders R
    LEFT JOIN 
        HighValueSuppliers S ON R.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_totalprice = R.o_totalprice)
    WHERE 
        R.rn <= 10
)
SELECT 
    c.o_orderkey,
    c.o_orderdate,
    c.o_totalprice,
    c.c_name,
    NVL(c.s_name, 'No Supplier') AS Supplier_Name,
    NVL(c.total_supplycost, 0) AS Total_Supply_Cost
FROM 
    CombinedData c
ORDER BY 
    c.o_totalprice DESC, 
    c.o_orderdate ASC;
