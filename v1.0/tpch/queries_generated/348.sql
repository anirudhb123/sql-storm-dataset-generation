WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.total_supply_cost,
    ro.o_orderkey,
    ro.o_totalprice,
    ro.o_orderdate,
    ro.c_mktsegment
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier_summary ss ON ps.ps_suppkey = ss.s_suppkey
LEFT JOIN 
    ranked_orders ro ON ro.o_orderkey = (
        SELECT 
            o.o_orderkey
        FROM 
            orders o
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE 
            l.l_partkey = p.p_partkey
        ORDER BY 
            o.o_orderdate DESC
        LIMIT 1
    )
WHERE 
    (ss.total_supply_cost > 1000 OR ss.part_count IS NULL)
    AND ro.price_rank <= 5
ORDER BY 
    p.p_partkey, ro.o_orderdate DESC;
