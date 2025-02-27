WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        r.n_regionkey, 
        r.r_name, 
        COUNT(DISTINCT rs.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        RankedSuppliers rs ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = rs.s_suppkey)
    WHERE 
        rs.supplier_rank = 1
    GROUP BY 
        r.n_regionkey, r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalReport AS (
    SELECT 
        ts.r_name AS region_name,
        co.total_orders,
        ts.supplier_count
    FROM 
        TopSuppliers ts
    LEFT JOIN 
        CustomerOrders co ON ts.n_regionkey = (SELECT n.n_regionkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey = ts.supplier_count)
)
SELECT 
    region_name, 
    total_orders,
    supplier_count
FROM 
    FinalReport
WHERE 
    total_orders > 10000
ORDER BY 
    supplier_count DESC, total_orders DESC;
