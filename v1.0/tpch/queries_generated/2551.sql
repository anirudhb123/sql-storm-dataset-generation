WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
region_orders AS (
    SELECT 
        n.n_regionkey,
        SUM(o.o_totalprice) AS region_total
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_regionkey
),
ranked_suppliers AS (
    SELECT 
        s.*, 
        RANK() OVER (ORDER BY total_cost DESC) AS cost_rank
    FROM 
        supplier_summary s
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    r.r_name,
    rs.s_name,
    rs.total_cost,
    rs.part_count,
    lo.item_count,
    lo.total_revenue
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    ranked_suppliers rs ON n.n_nationkey = (SELECT s_nationkey 
                                              FROM supplier 
                                              WHERE s_suppkey = rs.s_suppkey 
                                              LIMIT 1)
LEFT JOIN 
    lineitem_summary lo ON lo.l_orderkey = (SELECT o_orderkey 
                                             FROM orders 
                                             WHERE o_orderdate = (SELECT MAX(o_orderdate) 
                                                                  FROM orders 
                                                                  WHERE o_custkey = c.c_custkey)
                                             LIMIT 1)
WHERE 
    r.r_name IS NOT NULL AND 
    rs.cost_rank <= 10
ORDER BY 
    r.r_name, rs.total_cost DESC;
