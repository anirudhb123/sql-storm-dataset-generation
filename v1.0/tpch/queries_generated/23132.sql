WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
aggregated_sales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(NULLIF(s.s_comment, ''), 'No comments provided') AS supplier_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
combined_results AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        asales.p_name,
        asales.total_sales,
        si.supplier_comment,
        ROW_NUMBER() OVER (PARTITION BY ro.o_orderdate ORDER BY asales.total_sales DESC) AS sales_rank
    FROM 
        ranked_orders ro
    JOIN 
        aggregated_sales asales ON ro.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_orderdate = ro.o_orderdate)
    LEFT JOIN 
        supplier_info si ON si.s_suppkey = (
            SELECT 
                ps.ps_suppkey 
            FROM 
                partsupp ps 
            JOIN 
                part p ON ps.ps_partkey = p.p_partkey 
            WHERE 
                p.p_partkey = asales.p_partkey 
            ORDER BY 
                ps.ps_supplycost DESC 
            LIMIT 1
        )
)
SELECT 
    c.c_custkey,
    c.c_name,
    cr.total_sales AS customer_total_sales,
    cr.order_count AS customer_order_count,
    COALESCE(cr.supplier_comment, 'Supplier information not available') AS provider_feedback
FROM 
    customer c
LEFT JOIN 
    (SELECT 
        ar.p_name,
        SUM(ar.total_sales) AS total_sales,
        COUNT(DISTINCT ar.o_orderkey) AS order_count
    FROM 
        combined_results ar
    WHERE 
        ar.sales_rank <= 10
    GROUP BY 
        ar.p_name) cr ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ar.o_orderkey LIMIT 1)
WHERE 
    c.c_acctbal IS NOT NULL
ORDER BY 
    customer_total_sales DESC NULLS LAST;
