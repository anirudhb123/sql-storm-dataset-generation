WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn,
        SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN
        lineitem ol ON o.o_orderkey = ol.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
active_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_availability
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 0
    GROUP BY 
        s.s_suppkey, s.s_name
),
filtered_region AS (
    SELECT 
        r.r_regionkey
    FROM 
        region r
    WHERE 
        r.r_name NOT IN ('unknown', 'other')
)
SELECT 
    c.c_name,
    cs.order_count,
    cs.total_spent,
    ro.total_revenue,
    asu.total_availability,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY cs.total_spent DESC) AS cust_rank
FROM 
    customer_summary cs
JOIN 
    customer c ON cs.c_custkey = c.c_custkey
LEFT JOIN 
    ranked_orders ro ON cs.order_count > 0 AND ro.o_orderkey IN (
        SELECT 
            o.o_orderkey 
        FROM 
            orders o 
        WHERE 
            DATE_PART('year', o.o_orderdate) = 2023 
            AND o.o_orderstatus NOT LIKE 'F%'
    )
LEFT JOIN 
    active_suppliers asu ON ro.o_orderkey = (
        SELECT 
            l.l_orderkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_suppkey = asu.s_suppkey 
            ORDER BY l.l_shipdate DESC 
            LIMIT 1
    ) AND asu.total_availability IS NOT NULL
WHERE 
    EXISTS (
        SELECT 1 
        FROM filtered_region fr 
        WHERE fr.r_regionkey = (
            SELECT n.n_regionkey 
            FROM nation n 
            WHERE n.n_nationkey = c.c_nationkey
        )
    )
ORDER BY 
    cs.total_spent DESC NULLS LAST;
