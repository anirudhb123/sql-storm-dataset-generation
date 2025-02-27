
WITH OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
)
SELECT 
    os.o_orderkey,
    os.total_revenue,
    os.unique_suppliers,
    tp.p_name,
    ss.avg_supply_cost,
    CASE 
        WHEN os.total_revenue > 100000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    OrderStats os
JOIN 
    TopParts tp ON os.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = tp.p_partkey
    )
LEFT JOIN 
    SupplierStats ss ON tp.p_partkey = ss.ps_partkey
ORDER BY 
    os.total_revenue DESC, tp.total_quantity_sold DESC
LIMIT 50;
