WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    n.r_name AS region_name,
    rs.s_name AS supplier_name,
    ro.o_orderkey,
    rc.c_name AS customer_name,
    rc.o_totalprice,
    rs.total_supply_cost
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON rs.nation_name = n.n_name
JOIN 
    CustomerOrders ro ON ro.o_orderkey IN (
        SELECT o_orderkey 
        FROM orders 
        WHERE o_totalprice > 10000
    )
JOIN 
    customer rc ON ro.c_custkey = rc.c_custkey
WHERE 
    rs.supplier_rank <= 5
ORDER BY 
    n.r_name, rs.total_supply_cost DESC, ro.o_orderdate DESC;
