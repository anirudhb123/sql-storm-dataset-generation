WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
high_value_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        total_revenue,
        revenue_rank
    FROM 
        ranked_orders
    WHERE 
        revenue_rank <= 10
)
SELECT 
    ho.o_orderkey,
    ho.o_orderdate,
    ho.total_revenue,
    c.c_name,
    n.n_name AS nation,
    s.s_name AS supplier_name,
    ps.ps_supplycost,
    CASE 
        WHEN ho.total_revenue IS NULL THEN 'No Revenue'
        ELSE CONCAT('Revenue: $', TO_CHAR(ho.total_revenue, 'FM999,999,999.00'))
    END AS revenue_description
FROM 
    high_value_orders ho
LEFT JOIN 
    customer c ON c.c_custkey = (
        SELECT 
            o.o_custkey 
        FROM 
            orders o 
        WHERE 
            o.o_orderkey = ho.o_orderkey
    )
LEFT JOIN 
    supplier s ON s.s_suppkey IN (
        SELECT 
            l.l_suppkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_orderkey = ho.o_orderkey
    )
LEFT JOIN 
    partsupp ps ON ps.ps_partkey IN (
        SELECT 
            l.l_partkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_orderkey = ho.o_orderkey
    )
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    ho.total_revenue > 1000
ORDER BY 
    ho.total_revenue DESC, ho.o_orderdate;
