WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank_supplier
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 0 OR SUM(o.o_totalprice) IS NULL
),
LineitemDetails AS (
    SELECT 
        l.*, 
        DENSE_RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_discount DESC) AS discount_rank
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'R' AND 
        l.l_quantity BETWEEN 1 AND 100
),
NationPart AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        p.p_partkey, 
        p.p_name, 
        COUNT(DISTINCT l.l_orderkey) AS related_orders
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey, n.n_name, p.p_partkey, p.p_name
)
SELECT 
    c.c_custkey,
    c.c_name,
    ps.s_name,
    ps.total_avail_qty,
    np.n_name,
    ld.discount_rank,
    COALESCE(ld.l_shipdate, '1900-01-01') AS first_ship_date,
    CASE 
        WHEN c.order_count > 10 THEN 'High Volume'
        WHEN c.order_count BETWEEN 5 AND 10 THEN 'Moderate Volume'
        ELSE 'Low Volume'
    END AS customer_order_volume,
    (SELECT AVG(o.o_totalprice) 
     FROM orders o 
     WHERE o.o_orderstatus IN ('F', 'O') 
     AND o.o_orderdate >= DATEADD(month, -6, GETDATE())) AS avg_recent_order_value
FROM 
    CustomerOrders c
JOIN 
    RankedSuppliers ps ON c.c_custkey = ps.s_suppkey
JOIN 
    LineitemDetails ld ON ld.l_orderkey = (
        SELECT MAX(l_inner.l_orderkey)
        FROM LineitemDetails l_inner 
        WHERE l_inner.l_suppkey = ps.s_suppkey
    )
JOIN 
    NationPart np ON np.n_nationkey = ps.s_nationkey
WHERE 
    (np.related_orders > 0 OR c.order_count IS NULL)
    AND (ps.total_avail_qty IS NOT NULL OR np.n_name IS NOT NULL)
ORDER BY 
    customer_order_volume DESC, 
    ps.total_avail_qty ASC;
