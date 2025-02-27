WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ts.region_name,
    ts.nation_name,
    ts.s_name,
    co.c_custkey,
    co.c_name,
    co.total_spent,
    co.total_orders
FROM 
    TopSuppliers ts
JOIN 
    CustomerOrders co ON ts.s_nationkey = (
        SELECT n.n_nationkey
        FROM nation n
        WHERE ts.region_name = (
            SELECT r.r_name
            FROM region r
            WHERE r.r_regionkey = n.n_regionkey
        )
    )
ORDER BY 
    ts.region_name, ts.nation_name, ts.total_supply_cost DESC, co.total_spent DESC;
