
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1997-10-01'
),
TotalSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    INNER JOIN 
        RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    GROUP BY 
        l.l_orderkey
),
SupplierStats AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
CustomerSegments AS (
    SELECT 
        c.c_mktsegment,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(c.c_acctbal) AS total_account_balance
    FROM 
        customer c
    GROUP BY 
        c.c_mktsegment
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ts.total_sales,
    ss.total_supply_cost,
    cs.customer_count,
    cs.total_account_balance
FROM 
    RankedOrders ro
LEFT JOIN 
    TotalSales ts ON ro.o_orderkey = ts.l_orderkey
LEFT JOIN 
    SupplierStats ss ON ss.ps_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10))
LEFT JOIN 
    CustomerSegments cs ON cs.c_mktsegment = (SELECT c.c_mktsegment FROM customer c WHERE c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ro.o_orderkey LIMIT 1))
WHERE 
    ro.rn <= 10
ORDER BY 
    ro.o_orderdate DESC;
