WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice, 
           o_orderdate, o_orderpriority, o_clerk, o_shippriority, 
           o_comment, 1 AS hierarchy_level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice, 
           o.o_orderdate, o.o_orderpriority, o.o_clerk, o.o_shippriority, 
           o.o_comment, oh.hierarchy_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderkey > oh.o_orderkey AND o.o_orderstatus = 'O'
),

AggregateData AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           AVG(l.l_extendedprice) AS avg_price_per_item,
           MAX(o.o_totalprice) AS max_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
),

SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(ps.ps_availqty) AS total_available_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),

OrderedResults AS (
    SELECT ROW_NUMBER() OVER (PARTITION BY ad.total_orders ORDER BY ad.total_returned DESC) AS rn,
           ad.c_custkey, ad.c_name, ad.total_returned, ad.total_orders, 
           sp.s_suppkey, sp.s_name, sp.total_available_qty,
           sp.avg_supply_cost
    FROM AggregateData ad
    JOIN SupplierPerformance sp ON ad.total_orders > 5 AND ad.total_returned > 0
)

SELECT or.rn, or.c_custkey, or.c_name, or.total_returned, or.total_orders, 
       COALESCE(MAX(or.total_available_qty) OVER (PARTITION BY or.total_orders), 0) AS max_supplier_avail_qty,
       CASE 
            WHEN or.total_returned > 10 THEN 'High Return'
            WHEN or.total_returned BETWEEN 5 AND 10 THEN 'Moderate Return'
            ELSE 'Low Return'
       END AS return_category
FROM OrderedResults or
WHERE or.total_orders IS NOT NULL AND or.total_available_qty IS NOT NULL
ORDER BY or.total_orders DESC, or.total_returned DESC;
