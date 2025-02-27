WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    ro.o_orderkey,
    ro.o_orderstatus,
    ro.o_totalprice,
    ro.o_orderdate,
    ro.o_orderpriority,
    ss.s_name,
    ss.total_supply_cost,
    hc.c_name AS high_value_customer_name,
    hc.order_count
FROM 
    RankedOrders ro
LEFT JOIN 
    SupplierStats ss ON ss.parts_supplied > 10
JOIN 
    HighValueCustomers hc ON hc.order_count >= 5
WHERE 
    ro.order_rank <= 10
ORDER BY 
    ro.o_totalprice DESC, hc.order_count DESC;
