WITH supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (ORDER BY total_available DESC) AS rn
    FROM 
        supplier_stats s
    WHERE 
        s.total_available > (
            SELECT AVG(total_available) FROM supplier_stats
        )
), 
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ts.s_name,
    ts.total_available,
    os.total_revenue,
    os.unique_parts,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Revenue'
        WHEN ts.total_available IS NULL THEN 'Supplier Not Available'
        ELSE 'Valid Transaction'
    END AS transaction_status
FROM 
    top_suppliers ts
FULL OUTER JOIN 
    order_summary os ON ts.s_suppkey = os.o_orderkey
WHERE 
    (ts.rn <= 5 OR os.total_revenue > 10000)
ORDER BY 
    ts.total_available DESC NULLS LAST, 
    os.total_revenue DESC NULLS LAST;
