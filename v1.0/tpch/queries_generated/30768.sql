WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        1 AS order_level
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL

    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        co.order_level + 1 
    FROM 
        CustomerOrders co
    JOIN 
        orders o ON co.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate > (
            SELECT MAX(o2.o_orderdate)
            FROM orders o2
            WHERE o2.o_custkey = co.c_custkey
              AND o2.o_orderstatus = 'O'
        )
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
LineItemData AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_linenumber) AS line_count
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    co.c_name,
    co.o_orderkey,
    co.o_orderdate,
    COALESCE(p.p_name, 'Unknown Part') AS part_name,
    ps.total_avail_qty,
    l.revenue,
    ROW_NUMBER() OVER (PARTITION BY co.c_name ORDER BY l.revenue DESC) AS rank
FROM 
    CustomerOrders co
LEFT JOIN 
    LineItemData l ON co.o_orderkey = l.l_orderkey
LEFT JOIN 
    PartStats ps ON l.line_count >= (SELECT AVG(line_count) FROM LineItemData)
LEFT JOIN 
    partsupp ps2 ON ps.p_partkey = ps2.ps_partkey
LEFT JOIN 
    part p ON ps2.ps_partkey = p.p_partkey
WHERE 
    co.order_level <= 5
ORDER BY 
    co.c_name,
    rank;
