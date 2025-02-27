WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_avail_qty
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY 
        o.o_orderkey, c.c_custkey
),
TopOrders AS (
    SELECT 
        od.o_orderkey,
        od.c_custkey,
        od.order_value
    FROM 
        OrderDetails od
    WHERE 
        od.order_rank <= 10
)
SELECT 
    ss.s_name,
    ss.total_parts_supplied,
    ss.total_supply_cost,
    ss.avg_avail_qty,
    COALESCE(to.order_value, 0) AS top_order_value
FROM 
    SupplierStats ss
LEFT JOIN 
    TopOrders to ON ss.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            JOIN orders o ON l.l_orderkey = o.o_orderkey 
            WHERE o.o_orderkey IN (SELECT o_orderkey FROM TopOrders)
        )
        LIMIT 1
    )
ORDER BY 
    ss.total_supply_cost DESC, ss.s_name ASC;
