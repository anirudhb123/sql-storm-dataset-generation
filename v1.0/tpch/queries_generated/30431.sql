WITH RECURSIVE order_totals AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        1 AS level
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
    UNION ALL
    SELECT 
        ot.o_orderkey,
        ot.o_totalprice,
        c.c_name,
        c.c_nationkey,
        level + 1
    FROM 
        order_totals ot
    JOIN 
        lineitem l ON ot.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        customer c ON s.s_nationkey = c.c_nationkey
    WHERE 
        ot.level < 5
),
ranked_orders AS (
    SELECT 
        ot.o_orderkey,
        ot.o_totalprice,
        ot.c_name,
        nt.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY nt.n_name ORDER BY ot.o_totalprice DESC) AS rank,
        COALESCE(NULLIF(SUM(l.l_extendedprice * (1 - l.l_discount)), 0), -1) AS adjusted_revenue
    FROM 
        order_totals ot
    LEFT JOIN 
        nation nt ON ot.c_nationkey = nt.n_nationkey
    LEFT JOIN 
        lineitem l ON ot.o_orderkey = l.l_orderkey
    GROUP BY 
        ot.o_orderkey, ot.o_totalprice, ot.c_name, nt.n_name
)
SELECT 
    r.nation_name,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    SUM(ro.adjusted_revenue) AS total_revenue
FROM 
    ranked_orders ro
JOIN 
    nation r ON ro.nation_name = r.n_name
WHERE 
    ro.rank <= 10
GROUP BY 
    r.nation_name
ORDER BY 
    total_revenue DESC;
