WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_type
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierOrderDetails AS (
    SELECT 
        h.o_orderkey,
        h.total_order_value,
        s.s_name,
        r.r_name
    FROM 
        HighValueOrders h
    JOIN 
        lineitem l ON h.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sod.o_orderkey,
    sod.total_order_value,
    sod.s_name,
    COUNT(DISTINCT sod.s_name) OVER () AS unique_suppliers,
    AVG(sup.total_supply_cost) AS avg_supply_cost
FROM 
    SupplierOrderDetails sod
JOIN 
    RankedSuppliers sup ON sod.s_name = sup.s_name
ORDER BY 
    sod.total_order_value DESC
LIMIT 50;
