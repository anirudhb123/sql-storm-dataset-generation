WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        n.n_name AS nation_name,
        ss.total_avail_qty,
        ss.total_cost,
        RANK() OVER (PARTITION BY ss.nation_name ORDER BY ss.total_cost DESC) AS cost_rank
    FROM 
        SupplierStats ss
    JOIN 
        nation n ON ss.s_nationkey = n.n_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ts.s_name,
    ts.nation_name,
    ts.total_avail_qty,
    ts.total_cost,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent
FROM 
    TopSuppliers ts
JOIN 
    CustomerOrders co ON ts.total_avail_qty > 100000 AND ts.cost_rank <= 10
ORDER BY 
    ts.nation_name, ts.total_cost DESC, co.total_spent DESC;
