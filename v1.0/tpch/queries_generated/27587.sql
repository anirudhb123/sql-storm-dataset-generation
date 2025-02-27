WITH SupplierInfo AS (
    SELECT 
        s.s_name,
        n.n_name AS nation_name,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        CONCAT('Supplier: ', s.s_name, ' | Nation: ', n.n_name) AS supplier_nation_info,
        CASE 
            WHEN ps.ps_availqty < 50 THEN 'Low Stock'
            WHEN ps.ps_availqty >= 50 AND ps.ps_availqty < 200 THEN 'Medium Stock'
            ELSE 'High Stock' 
        END AS stock_level
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100.00
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
)

SELECT 
    si.supplier_nation_info,
    si.p_name,
    si.ps_supplycost,
    si.stock_level,
    os.o_orderkey,
    os.total_line_items,
    os.total_revenue,
    os.last_order_date
FROM 
    SupplierInfo si
JOIN 
    OrderSummary os ON si.ps_supplycost < os.total_revenue / os.total_line_items
ORDER BY 
    os.total_revenue DESC, si.stock_level;
