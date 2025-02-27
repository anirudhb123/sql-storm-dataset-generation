WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey, n.n_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MIN(o.o_orderdate) AS first_order_date,
        MAX(o.o_orderdate) AS last_order_date,
        COUNT(DISTINCT o.o_orderstatus) AS order_status_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    rs.nation_name,
    rs.s_name,
    rs.total_cost AS total_supplier_cost,
    os.total_revenue,
    os.first_order_date,
    os.last_order_date,
    os.order_status_count
FROM 
    RankedSuppliers rs
JOIN 
    OrderSummary os ON os.total_revenue > 0
WHERE 
    rs.rank <= 5
ORDER BY 
    rs.nation_name, total_supplier_cost DESC, os.total_revenue DESC;
