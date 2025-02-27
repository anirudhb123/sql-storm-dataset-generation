WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS rank_cust
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 5000
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_totalprice
)
SELECT 
    n.n_name AS nation_name,
    hs.s_name AS supplier_name,
    hv.c_name AS customer_name,
    ro.total_order_value,
    ro.o_totalprice,
    hv.c_acctbal,
    RANK() OVER (PARTITION BY n.n_nationkey ORDER BY ro.total_order_value DESC) AS order_rank
FROM 
    nation n
LEFT JOIN 
    RankedSuppliers hs ON n.n_nationkey = hs.s_nationkey AND hs.rank = 1
LEFT JOIN 
    RecentOrders ro ON hs.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE l.l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
    )
JOIN 
    HighValueCustomers hv ON ro.o_custkey = hv.c_custkey
WHERE 
    n.n_regionkey IS NOT NULL
ORDER BY 
    nation_name, order_rank;
