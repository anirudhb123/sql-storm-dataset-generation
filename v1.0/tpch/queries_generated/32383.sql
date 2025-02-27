WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_totalprice, o_orderdate
    FROM orders
    WHERE o_orderdate >= DATE '2023-01-01'
    
    UNION ALL
    
    SELECT o.orderkey, o.custkey, o.totalprice, o.orderdate
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
AggregatedData AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_price,
        ROW_NUMBER() OVER (PARTITION BY s.s_name ORDER BY SUM(ps.ps_supplycost * l.l_quantity) DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN OrderHierarchy o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_shipdate < CURRENT_DATE
    GROUP BY s.s_name, p.p_name
),
FinalOutput AS (
    SELECT 
        supplier_name,
        part_name,
        total_supply_cost,
        order_count,
        avg_order_price
    FROM AggregatedData
    WHERE rn = 1
)
SELECT 
    fo.supplier_name,
    fo.part_name,
    fo.total_supply_cost,
    fo.order_count,
    fo.avg_order_price,
    r.r_name AS region_name,
    CASE
        WHEN fo.order_count IS NULL THEN 'No Orders'
        ELSE 'Orders Available'
    END AS order_status
FROM FinalOutput fo
LEFT JOIN supplier s ON fo.supplier_name = s.s_name
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
ORDER BY fo.total_supply_cost DESC, fo.avg_order_price DESC;
