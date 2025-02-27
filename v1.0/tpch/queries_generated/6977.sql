WITH SupplierStatistics AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        SUM(ps.ps_availqty) AS total_available_qty,
        COUNT(DISTINCT p.p_partkey) AS distinct_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_supply_cost,
        s.total_available_qty,
        s.distinct_parts_supplied,
        RANK() OVER (ORDER BY s.total_supply_cost DESC) AS rank
    FROM 
        SupplierStatistics s
)
SELECT 
    c.c_custkey,
    c.c_name,
    t.s_suppkey,
    t.s_name,
    t.total_supply_cost,
    t.total_available_qty,
    t.distinct_parts_supplied,
    co.total_orders,
    co.total_spent
FROM 
    CustomerOrderSummary co
JOIN 
    TopSuppliers t ON co.total_spent >= 1000
JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    t.rank <= 10
ORDER BY 
    co.total_spent DESC, t.total_supply_cost DESC
LIMIT 50;
