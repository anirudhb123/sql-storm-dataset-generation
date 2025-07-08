
WITH RECURSIVE regional_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        1 AS level
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')

    UNION ALL

    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        level + 1 
    FROM 
        supplier s
    JOIN 
        regional_suppliers rs ON s.s_nationkey = rs.s_nationkey
    WHERE 
        s.s_acctbal <> rs.s_acctbal
),

aggregated_orders AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY o.o_totalprice) AS median_spent 
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),

lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
        MAX(l.l_tax) AS highest_tax_rate
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)

SELECT 
    ns.n_name AS nation_name,
    COALESCE(SUM(a.total_spent), 0) AS total_spent_by_nation,
    LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS products_supplied,
    RANK() OVER (PARTITION BY ns.n_name ORDER BY COALESCE(SUM(a.total_spent), 0) DESC) AS rank_in_nation,
    CASE 
        WHEN SUM(ls.total_price_after_discount) IS NULL THEN 'No Orders'
        ELSE 'Order Summary'
    END AS order_summary_status
FROM 
    nation ns
LEFT JOIN 
    aggregated_orders a ON ns.n_nationkey = a.o_custkey
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = ns.n_nationkey LIMIT 1)
LEFT JOIN 
    part p ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem_summary ls ON ls.l_orderkey = a.o_custkey
WHERE 
    ns.n_nationkey IN (SELECT DISTINCT n.n_nationkey FROM nation n WHERE n.n_comment IS NOT NULL AND n.n_name LIKE 'A%')
GROUP BY 
    ns.n_name
HAVING 
    COUNT(p.p_partkey) > 0 OR ns.n_name IS NULL
ORDER BY 
    rank_in_nation, products_supplied;
