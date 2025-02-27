WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_clerk,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_clerk ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_clerk
),
SupplierMarket AS (
    SELECT 
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_name, n.n_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS acctbal_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.o_clerk,
    sm.nation_name,
    sm.total_supply_cost,
    hu.c_custkey,
    hu.c_name AS high_value_cust
FROM 
    RankedOrders ro
LEFT OUTER JOIN 
    SupplierMarket sm ON sm.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierMarket)
LEFT OUTER JOIN 
    HighValueCustomers hu ON hu.acctbal_rank <= 10
WHERE 
    ro.sales_rank <= 5
ORDER BY 
    ro.o_orderdate DESC, ro.o_orderkey;
