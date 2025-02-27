WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
OrdersSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS items_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        s.s_name,
        DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderkey DESC) AS order_rank
    FROM 
        OrdersSummary o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON c.c_nationkey = s.s_nationkey
    WHERE 
        o.total_revenue > (SELECT AVG(total_revenue) FROM OrdersSummary)
)
SELECT 
    o.o_orderkey,
    o.total_revenue,
    o.items_count,
    s.total_available,
    s.avg_supplycost,
    COALESCE(h.order_rank, 0) AS rank
FROM 
    OrdersSummary o
LEFT JOIN 
    SupplierStats s ON s.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE l.l_orderkey = o.o_orderkey 
        LIMIT 1
    )
LEFT JOIN 
    HighValueOrders h ON o.o_orderkey = h.o_orderkey
WHERE 
    s.total_available IS NOT NULL
ORDER BY 
    o.total_revenue DESC
FETCH FIRST 100 ROWS ONLY;
