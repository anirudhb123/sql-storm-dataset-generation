
WITH RECURSIVE tbl AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT li.l_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS rank_ordered
    FROM 
        orders o 
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        li.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        r.region_name,
        t.total_revenue,
        t.supplier_count,
        t.rank_ordered
    FROM 
        tbl t
    JOIN 
        orders o ON o.o_orderkey = t.o_orderkey
    LEFT JOIN 
        (SELECT 
            n.n_nationkey,
            r.r_name AS region_name
        FROM 
            nation n
        JOIN 
            region r ON n.n_regionkey = r.r_regionkey) r ON r.n_nationkey = (
                SELECT s.s_nationkey 
                FROM supplier s 
                WHERE s.s_suppkey IN (SELECT DISTINCT l.l_suppkey FROM lineitem l)
                LIMIT 1
            )
    WHERE 
        t.rank_ordered <= 10
),
summary AS (
    SELECT 
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value,
        SUM(o.o_totalprice) AS total_value
    FROM 
        ranked_orders o
    WHERE 
        o.region_name IS NOT NULL
)
SELECT 
    ro.rank_ordered,
    ro.o_orderkey,
    ro.o_totalprice,
    ro.o_orderstatus,
    COALESCE(ro.region_name, 'Unknown Region') AS resolved_region,
    COALESCE(s.order_count, 0) AS order_count,
    COALESCE(s.avg_order_value, 0) AS avg_order_value,
    COALESCE(s.total_value, 0) AS total_value,
    CASE 
        WHEN ro.o_totalprice > (SELECT AVG(o.o_totalprice) FROM orders o) THEN 'Above Average'
        ELSE 'Below Average'
    END AS price_comparison
FROM 
    ranked_orders ro
LEFT JOIN 
    summary s ON true  
ORDER BY 
    ro.rank_ordered;
