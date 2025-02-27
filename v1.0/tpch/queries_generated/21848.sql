WITH recursive nation_orders AS (
    SELECT 
        n.n_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        n.n_name, o.o_orderkey, o.o_orderdate
), high_revenue AS (
    SELECT 
        n.n_name,
        AVG(total_revenue) AS avg_revenue,
        COUNT(DISTINCT o_orderkey) AS order_count
    FROM 
        nation_orders
    GROUP BY 
        n.n_name
    HAVING 
        COUNT(DISTINCT o_orderkey) > 10 AND AVG(total_revenue) > 1000
), suppliers_per_order AS (
    SELECT 
        o.o_orderkey, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    h.n_name,
    h.avg_revenue,
    s.supplier_count,
    CASE 
        WHEN s.supplier_count IS NULL THEN 'No Suppliers'
        ELSE 'Suppliers Available'
    END AS supplier_status,
    CASE 
        WHEN h.order_count = 1 THEN 'Single Order'
        WHEN h.order_count BETWEEN 2 AND 5 THEN 'Few Orders'
        ELSE 'Many Orders'
    END AS order_category
FROM 
    high_revenue h
LEFT JOIN 
    suppliers_per_order s ON h.n_name = (
        SELECT n.n_name 
        FROM nation n 
        WHERE n.n_nationkey = (
            SELECT c.c_nationkey 
            FROM customer c 
            JOIN orders o ON o.o_custkey = c.c_custkey 
            WHERE o.o_orderkey = s.o_orderkey
            LIMIT 1
        )
    )
ORDER BY 
    h.avg_revenue DESC NULLS LAST, 
    s.supplier_count DESC NULLS FIRST;
