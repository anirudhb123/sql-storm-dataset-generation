WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerTotalSpend AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cts.c_name,
    COALESCE(cts.total_spent, 0) AS total_spent,
    COALESCE(ss.total_available, 0) AS total_available,
    ss.average_supply_cost,
    ro.o_orderkey,
    ro.o_orderstatus
FROM 
    CustomerTotalSpend cts
LEFT JOIN 
    SupplierSummary ss ON ss.total_available > 100
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_orderstatus = 'O' AND o_orderkey % 2 = 0)
WHERE 
    cts.total_spent > 1000
ORDER BY 
    cts.total_spent DESC, ss.average_supply_cost ASC
LIMIT 10;

