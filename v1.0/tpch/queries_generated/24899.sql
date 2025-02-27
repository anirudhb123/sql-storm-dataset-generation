WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ROW_NUMBER() OVER (PARTITION BY ns.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation ns ON s.s_nationkey = ns.n_nationkey
), 
part_info AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), 
filtered_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Fulfilled'
            WHEN o.o_orderstatus = 'O' THEN 'Open'
            ELSE 'Other'
        END AS order_status_transformed
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
)

SELECT 
    n.n_name AS nation_name, 
    STRING_AGG(DISTINCT ps.ps_comment) AS supplier_comments,
    p.p_name AS part_name,
    pi.total_available_qty,
    pi.avg_supply_cost,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
    COUNT(DISTINCT lo.l_orderkey) AS order_count
FROM 
    ranked_suppliers rs
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = rs.s_suppkey
JOIN 
    part_info pi ON pi.p_partkey = ps.ps_partkey
JOIN 
    lineitem lo ON lo.l_suppkey = ps.ps_suppkey
JOIN 
    nation n ON n.n_nationkey = rs.n_nationkey
JOIN 
    filtered_orders fo ON fo.o_orderkey = lo.l_orderkey
WHERE 
    pi.total_available_qty IS NOT NULL 
    AND (pi.avg_supply_cost < 20 OR pi.avg_supply_cost IS NULL) 
GROUP BY 
    n.n_name, ps.ps_comment, p.p_name, pi.total_available_qty, pi.avg_supply_cost
HAVING 
    COUNT(DISTINCT lo.l_orderkey) > 10 
ORDER BY 
    total_revenue DESC 
FETCH FIRST 10 ROWS ONLY;
