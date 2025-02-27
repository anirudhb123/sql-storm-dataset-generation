
WITH RECURSIVE supply_chain AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        1 AS depth
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty IS NOT NULL
    UNION ALL
    SELECT 
        p.ps_partkey,
        p.ps_suppkey,
        (sc.ps_availqty * 0.9) AS ps_availqty,
        (sc.ps_supplycost + 10) AS ps_supplycost,
        sc.depth + 1
    FROM 
        supply_chain sc
    JOIN 
        partsupp p ON sc.ps_partkey = p.ps_partkey
    WHERE 
        sc.depth < 5
),
nation_summary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal,
        AVG(s.s_acctbal) AS average_acctbal,
        MAX(s.s_acctbal) AS max_acctbal,
        MIN(s.s_acctbal) AS min_acctbal,
        CASE 
            WHEN SUM(s.s_acctbal) IS NOT NULL THEN 'Active'
            ELSE 'Inactive'
        END AS activity_status
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 0 
        AND MAX(s.s_acctbal) > 100
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
final_report AS (
    SELECT 
        ns.n_name,
        ns.supplier_count,
        ns.total_acctbal,
        ns.average_acctbal,
        os.total_revenue,
        CASE 
            WHEN os.total_revenue IS NULL THEN 'No Orders'
            WHEN ns.total_acctbal / NULLIF(ns.supplier_count, 0) > 5000 THEN 'High Value'
            ELSE 'Standard'
        END AS value_segment
    FROM 
        nation_summary ns
    LEFT JOIN 
        order_summary os ON ns.n_nationkey = os.o_custkey
)
SELECT 
    fr.n_name,
    fr.supplier_count,
    fr.total_acctbal,
    fr.average_acctbal,
    fr.total_revenue,
    fr.value_segment
FROM 
    final_report fr
WHERE 
    fr.supplier_count >= (
        SELECT COUNT(DISTINCT s.s_suppkey) 
        FROM supplier s 
        WHERE s.s_acctbal > (
            SELECT AVG(s_acctbal) FROM supplier WHERE s.s_suppkey IS NOT NULL
        )
    )
ORDER BY 
    fr.n_name ASC 
LIMIT 10;
