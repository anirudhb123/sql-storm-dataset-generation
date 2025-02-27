WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
HighVolumeOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, c.c_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierOrderDetails AS (
    SELECT 
        r.n_name AS nation_name,
        rs.s_name AS supplier_name,
        COUNT(ho.o_orderkey) AS order_count,
        SUM(ho.order_value) AS total_order_value
    FROM 
        RankedSuppliers rs
    JOIN 
        HighVolumeOrders ho ON rs.s_suppkey = ho.c_custkey
    JOIN 
        nation r ON rs.nation_name = r.n_name
    GROUP BY 
        r.n_name, rs.s_name
)
SELECT 
    nation_name,
    supplier_name,
    order_count,
    total_order_value,
    RANK() OVER (PARTITION BY nation_name ORDER BY total_order_value DESC) AS value_rank
FROM 
    SupplierOrderDetails
ORDER BY 
    nation_name, value_rank;
