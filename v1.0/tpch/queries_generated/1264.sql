WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
QualifiedOrders AS (
    SELECT 
        od.o_orderkey,
        od.total_price,
        od.part_count,
        ROW_NUMBER() OVER (PARTITION BY od.o_orderkey ORDER BY od.total_price DESC) AS price_rank
    FROM 
        OrderDetails od
    WHERE 
        od.total_price > (SELECT AVG(total_price) FROM OrderDetails)
)
SELECT 
    q.o_orderkey,
    q.total_price,
    q.part_count,
    ss.s_name,
    ss.total_avail_qty,
    ss.avg_supply_cost
FROM 
    QualifiedOrders q
LEFT JOIN 
    SupplierStats ss ON q.part_count = (SELECT COUNT(*) FROM partsupp WHERE ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = q.o_orderkey))
WHERE 
    ss.total_avail_qty IS NOT NULL
ORDER BY 
    q.total_price DESC
LIMIT 10;
