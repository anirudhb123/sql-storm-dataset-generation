WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_status
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_supply_cost DESC
    LIMIT 10
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    cs.c_name AS customer_name,
    cs.total_spent,
    cs.order_count,
    ts.s_name AS supplier_name,
    ts.total_supply_cost,
    ro.o_orderkey,
    ro.o_orderstatus,
    ro.o_totalprice
FROM 
    RankedOrders ro
JOIN 
    CustomerStats cs ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
JOIN 
    nation n ON n.n_nationkey IN (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = cs.c_custkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    TopSuppliers ts ON ts.total_supply_cost > 1000
WHERE 
    ro.rank_status <= 10
ORDER BY 
    r.r_name, n.n_name, cs.total_spent DESC;
