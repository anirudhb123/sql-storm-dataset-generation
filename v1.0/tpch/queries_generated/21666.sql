WITH regional_supplier_stats AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers,
        SUM(s.s_acctbal) AS total_account_balance,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
order_line_items AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1994-01-01' 
        AND l.l_shipdate < DATE '1995-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.nation_name,
    r.distinct_suppliers,
    r.total_account_balance,
    o.net_revenue,
    o.revenue_rank,
    CASE 
        WHEN o.net_revenue IS NULL THEN 'No Revenue'
        WHEN r.total_account_balance > 100000 THEN 'High Balance'
        ELSE 'Standard Balance'
    END AS account_status
FROM 
    regional_supplier_stats r
LEFT JOIN 
    order_line_items o ON r.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O') LIMIT 1))))
ORDER BY 
    r.distinct_suppliers DESC, 
    o.net_revenue ASC NULLS LAST;
