
WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey
),
RegionSupplier AS (
    SELECT 
        r.r_regionkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice) AS high_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_discount > 0.1
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice) > 10000
)
SELECT 
    os.o_orderkey,
    COALESCE(r.supplier_count, 0) AS supplier_count,
    os.total_revenue,
    CASE 
        WHEN os.rank_revenue = 1 THEN 'Top Order'
        WHEN os.rank_revenue = 2 AND os.total_revenue IS NOT NULL THEN 'Second Best Order'
        ELSE 'Other'
    END AS order_category,
    (SELECT COUNT(*) FROM HighValueOrders hvo WHERE hvo.o_orderkey = os.o_orderkey) AS high_value_order_flag
FROM 
    OrderSummary os
LEFT JOIN 
    RegionSupplier r ON os.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = os.o_orderkey LIMIT 1)
WHERE 
    os.total_revenue IS NOT NULL 
    AND os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE EXTRACT(YEAR FROM o.o_orderdate) = EXTRACT(YEAR FROM DATE '1998-10-01') - 1)
ORDER BY 
    os.total_revenue DESC
LIMIT 10;
