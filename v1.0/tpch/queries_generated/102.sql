WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
order_summary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
high_value_orders AS (
    SELECT 
        os.o_orderkey,
        os.total_revenue,
        CASE 
            WHEN os.total_revenue > (SELECT AVG(total_revenue) FROM order_summary) THEN 'High Value'
            ELSE 'Normal'
        END AS order_type
    FROM 
        order_summary os
),
nation_summary AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    n.n_name,
    ns.supplier_count,
    ns.total_acctbal,
    COALESCE(r.rank, 0) AS supplier_rank,
    COALESCE(hv.total_revenue, 0) AS order_revenue,
    hv.order_type
FROM 
    nation_summary ns
LEFT JOIN 
    ranked_suppliers r ON ns.n_nationkey = r.s_nationkey
LEFT JOIN 
    high_value_orders hv ON hv.o_orderkey = (SELECT MIN(o_orderkey) FROM high_value_orders ho WHERE ho.total_revenue = hv.total_revenue)
ORDER BY 
    ns.total_acctbal DESC, 
    n.n_name;
