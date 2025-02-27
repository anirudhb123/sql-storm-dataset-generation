WITH RECURSIVE nation_sales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        n.n_nationkey, n.n_name
),
top_nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        ns.total_sales
    FROM 
        nation n
    LEFT JOIN 
        nation_sales ns ON n.n_nationkey = ns.n_nationkey
    WHERE 
        ns.rn IS NULL OR ns.rn <= 3
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        COUNT(l.l_linenumber) AS item_count,
        o.o_orderdate,
        dense_rank() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
final_report AS (
    SELECT 
        tn.n_name,
        os.o_orderdate,
        os.order_total,
        os.item_count,
        CASE 
            WHEN os.order_total IS NULL THEN 'NO SALES'
            ELSE CASE 
                WHEN os.order_total > 1000 THEN 'HIGH VALUE'
                WHEN os.item_count > 5 THEN 'BULK ORDER'
                ELSE 'NORMAL'
            END
        END AS order_category
    FROM 
        top_nations tn
    FULL OUTER JOIN 
        order_summary os ON tn.n_nationkey = os.o_orderkey % 10   -- bizarrely linking nations to orders through modulus
)
SELECT 
    n.n_name,
    COALESCE(f.order_total, 0) AS total_order_value,
    COALESCE(f.item_count, 0) AS total_items_ordered,
    f.order_category
FROM 
    top_nations n
LEFT JOIN 
    final_report f ON n.n_name = f.n_name
ORDER BY 
    total_order_value DESC NULLS LAST;
