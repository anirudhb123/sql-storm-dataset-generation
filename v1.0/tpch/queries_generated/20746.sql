WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_clerk,
        o.o_shippriority,
        1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_clerk,
        o.o_shippriority,
        oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'O' AND oh.order_level < 10
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(ps.ps_partkey) AS total_parts,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        MAX(o.o_totalprice) AS max_order_value,
        CASE 
            WHEN COUNT(DISTINCT o.o_orderkey) = 0 THEN NULL 
            ELSE SUM(o.o_totalprice) / COUNT(DISTINCT o.o_orderkey) 
        END AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    COALESCE(cs.total_orders, 0) AS total_orders,
    cs.max_order_value,
    cs.avg_order_value,
    sd.s_name,
    sd.avg_supply_cost,
    sd.total_parts,
    sd.part_names,
    COUNT(oh.o_orderkey) FILTER (WHERE oh.o_orderstatus = 'O') OVER (PARTITION BY cs.c_custkey) AS open_orders_count,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey IN (SELECT oh.o_orderkey FROM OrderHierarchy oh WHERE oh.order_level = 1)) AS lineitems_in_open_orders
FROM CustomerSummary cs
LEFT JOIN SupplierDetails sd ON LENGTH(sd.s_name) > 5
LEFT JOIN OrderHierarchy oh ON cs.c_custkey = oh.o_orderkey
WHERE cs.avg_order_value IS NOT NULL OR sd.avg_supply_cost IS NOT NULL
ORDER BY cs.c_custkey, sd.s_name DESC;
