WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
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
        rs.s_name AS supplier_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
),
OrdersWithSupplier AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ts.supplier_name,
        ts.region_name,
        ts.nation_name
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        TopSuppliers ts ON l.l_suppkey = (SELECT s.s_suppkey FROM supplier s WHERE s.s_name = ts.supplier_name LIMIT 1)
)
SELECT 
    ows.region_name,
    ows.nation_name,
    COUNT(DISTINCT ows.o_orderkey) AS order_count,
    AVG(ows.o_totalprice) AS avg_order_value,
    MAX(ows.o_orderdate) AS last_order_date
FROM 
    OrdersWithSupplier ows
GROUP BY 
    ows.region_name, ows.nation_name
ORDER BY 
    ows.region_name, order_count DESC;
