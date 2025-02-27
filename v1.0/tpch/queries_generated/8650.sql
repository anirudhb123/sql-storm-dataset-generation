WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        total_spent > 10000
),
SupplierPartStats AS (
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
    HAVING 
        SUM(ps.ps_availqty) > 1000
)
SELECT 
    rc.o_orderkey,
    tc.c_name AS top_customer,
    sps.s_name AS supplier_name,
    rc.total_revenue,
    tc.total_spent,
    sps.total_supply_cost
FROM 
    RankedOrders rc
JOIN 
    TopCustomers tc ON rc.o_orderkey IN (SELECT o.o_orderkey FROM orders o JOIN customer c ON o.o_custkey = c.c_custkey WHERE c.c_custkey = tc.c_custkey)
JOIN 
    SupplierPartStats sps ON sps.total_supply_cost > 100000
ORDER BY 
    rc.total_revenue DESC, tc.total_spent DESC, sps.total_supply_cost DESC
LIMIT 10;
