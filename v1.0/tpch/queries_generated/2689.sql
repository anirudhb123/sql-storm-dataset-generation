WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availqty,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        DENSE_RANK() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_item_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
),
AggregatedOrderDetails AS (
    SELECT 
        od.o_orderkey,
        SUM(od.l_extendedprice * (1 - od.l_discount)) AS net_revenue,
        COUNT(od.l_partkey) AS line_item_count
    FROM 
        OrderDetails od
    GROUP BY 
        od.o_orderkey
)

SELECT 
    s.s_suppkey,
    s.s_name,
    ss.total_availqty,
    ss.unique_parts,
    c.c_custkey,
    co.order_count,
    co.total_spent,
    co.last_order_date,
    ao.o_orderkey,
    ao.net_revenue,
    ao.line_item_count
FROM 
    SupplierStats ss
JOIN 
    supplier s ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey FROM customer c ORDER BY c.c_acctbal DESC LIMIT 1)
LEFT JOIN 
    AggregatedOrderDetails ao ON ao.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F' ORDER BY o.o_orderdate DESC LIMIT 1)
WHERE 
    ss.total_availqty > 100
ORDER BY 
    net_revenue DESC NULLS LAST;
