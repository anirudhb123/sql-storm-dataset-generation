WITH RECURSIVE OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
HighValueOrders AS (
    SELECT 
        od.o_orderkey,
        od.total_revenue,
        COUNT(l.l_partkey) AS item_count
    FROM 
        OrderDetails od 
    JOIN 
        lineitem l ON od.o_orderkey = l.l_orderkey
    WHERE 
        od.total_revenue > 50000
    GROUP BY 
        od.o_orderkey, od.total_revenue
)
SELECT 
    o.o_orderkey,
    od.total_revenue,
    od.o_orderdate,
    COALESCE(c.c_name, 'Unknown') AS customer_name,
    COALESCE(s.s_name, 'Unknown') AS supplier_name
FROM 
    HighValueOrders hvo
JOIN 
    orders o ON hvo.o_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
WHERE 
    EXISTS (
        SELECT 1
        FROM partsupp ps
        WHERE ps.ps_partkey = l.l_partkey
        AND ps.ps_availqty > 0
    )
ORDER BY 
    total_revenue DESC, 
    o.o_orderdate ASC
LIMIT 10;
