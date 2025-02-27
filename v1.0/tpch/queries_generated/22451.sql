WITH OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linestatus) AS total_lines,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        os.total_revenue,
        os.total_lines,
        CUME_DIST() OVER (ORDER BY os.total_revenue DESC) AS revenue_percentile
    FROM 
        OrderStats os
    JOIN 
        orders o ON os.o_orderkey = o.o_orderkey
    WHERE 
        os.revenue_rank = 1
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COALESCE(SUM(os.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT t.o_orderkey) AS total_orders,
    AVG(ss.avg_supplycost) AS avg_supplier_cost,
    MAX(t.revenue_percentile) AS max_revenue_percentile
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders t ON c.c_custkey = t.o_custkey
LEFT JOIN 
    OrderStats os ON t.o_orderkey = os.o_orderkey
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (
            SELECT DISTINCT l.l_partkey 
            FROM lineitem l
            WHERE l.l_shipdate IS NOT NULL
        )
    )
GROUP BY 
    r.r_name, n.n_name
HAVING 
    (SUM(os.total_revenue) IS NOT NULL OR COUNT(DISTINCT t.o_orderkey) > 5)
    AND (MAX(ss.total_available_qty) IS NULL OR MAX(ss.total_available_qty) > 100)
ORDER BY 
    total_revenue DESC, max_revenue_percentile DESC;
