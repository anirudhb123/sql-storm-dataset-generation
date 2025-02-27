WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        ns.n_name,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        COALESCE(CAST(SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS DECIMAL(12, 2)), 0) AS open_orders_total,
        COALESCE(CAST(SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS DECIMAL(12, 2)), 0) AS finished_orders_total
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    ts.r_name,
    ts.n_name,
    ts.s_name,
    co.c_custkey,
    co.c_name,
    co.order_count,
    co.total_spent,
    os.open_orders_total,
    os.finished_orders_total
FROM 
    TopSuppliers ts
LEFT JOIN 
    CustomerOrders co ON co.custkey IN (SELECT c_custkey FROM customer WHERE c_nationkey = ts.n_nationkey)
LEFT JOIN 
    OrderSummary os ON os.c_custkey = co.c_custkey
WHERE 
    (co.total_spent IS NOT NULL OR os.open_orders_total > 0)
ORDER BY 
    ts.total_supply_cost DESC, co.total_spent DESC;
