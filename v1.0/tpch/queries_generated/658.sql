WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND
        o.o_orderdate < DATE '2023-01-01'
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
elementary_summary AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ess.revenue, 0) AS total_revenue,
    COALESCE(ess.order_count, 0) AS total_orders,
    s.s_name,
    s.total_availqty,
    s.avg_supplycost,
    CASE 
        WHEN ess.order_count IS NULL THEN 'No orders'
        ELSE 'Orders exist'
    END AS order_status,
    RANK() OVER (ORDER BY COALESCE(ess.revenue, 0) DESC) AS revenue_rank
FROM 
    part p
LEFT JOIN 
    elementary_summary ess ON p.p_partkey = ess.l_partkey
LEFT JOIN 
    supplier_summary s ON s.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey = p.p_partkey 
        ORDER BY 
            ps.ps_supplycost 
        LIMIT 1
    )
WHERE 
    p.p_retailprice > 100
ORDER BY 
    revenue_rank
FETCH FIRST 10 ROWS ONLY;
