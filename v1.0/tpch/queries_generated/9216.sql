WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s_suppkey, s_name
    FROM RankedSuppliers
    WHERE supply_rank <= 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
LineItemDetails AS (
    SELECT 
        lo.l_orderkey, 
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    cu.c_name AS customer_name,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(ld.total_revenue) AS total_revenue,
    ts.s_name AS top_supplier_name,
    ts.total_supply_cost
FROM 
    CustomerOrders co
JOIN 
    LineItemDetails ld ON co.o_orderkey = ld.l_orderkey
JOIN 
    TopSuppliers ts ON ts.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem li ON ps.ps_partkey = li.l_partkey
        WHERE li.l_orderkey = co.o_orderkey
    )
JOIN 
    customer cu ON co.c_custkey = cu.c_custkey
GROUP BY 
    cu.c_name, ts.s_name, ts.total_supply_cost
ORDER BY 
    total_revenue DESC, total_orders DESC
LIMIT 20;
