WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'P') 
        AND o.o_orderdate >= DATE '1995-01-01'
),
avg_supplier_cost AS (
    SELECT 
        p.ps_partkey,
        AVG(p.ps_supplycost) AS avg_cost
    FROM 
        partsupp p
    GROUP BY 
        p.ps_partkey
),
complex_subquery AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY 
        l.l_orderkey
),
combined_results AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        coalesce(s.total_sales, 0) AS total_sales,
        CASE 
            WHEN r.order_rank IS NULL THEN 'Not Ranked'
            ELSE CAST(r.order_rank AS VARCHAR)
        END AS sales_rank,
        CASE 
            WHEN a.avg_cost > 1000 THEN 'Expensive'
            ELSE 'Affordable'
        END AS cost_category
    FROM 
        ranked_orders r
    LEFT JOIN 
        complex_subquery s ON r.o_orderkey = s.l_orderkey
    LEFT JOIN 
        avg_supplier_cost a ON s.l_orderkey = a.ps_partkey
)
SELECT 
    c.c_name,
    c.c_acctbal,
    cr.cost_category,
    cr.total_sales,
    cr.sales_rank,
    CASE 
        WHEN cr.sales_rank = 'Not Ranked' THEN 'Rank Not Applicable'
        ELSE 'Rank Applicable'
    END AS rank_status
FROM 
    combined_results cr
JOIN 
    customer c ON c.c_custkey = (
        SELECT 
            o.o_custkey
        FROM 
            orders o
        WHERE 
            o.o_orderkey = cr.o_orderkey
        LIMIT 1
    )
WHERE 
    c.c_acctbal IS NOT NULL 
    AND cr.total_sales > 5000
ORDER BY 
    cr.total_sales DESC, c.c_name;
