
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_region
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    rs.nation_name,
    COUNT(DISTINCT ro.o_orderkey) AS unique_orders,
    SUM(ro.total_sales) AS total_sales_value,
    AVG(rs.total_supply_cost) AS avg_supply_cost_per_supplier,
    MAX(ro.total_sales) AS max_single_order_value
FROM 
    RankedSuppliers rs
JOIN 
    FilteredOrders ro ON rs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rs.s_suppkey LIMIT 1)
GROUP BY 
    rs.nation_name
ORDER BY 
    total_sales_value DESC, unique_orders DESC;
