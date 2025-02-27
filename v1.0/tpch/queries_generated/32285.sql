WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, 1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.order_level < 10
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerSegment AS (
    SELECT c.c_mktsegment, COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_mktsegment
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedParts AS (
    SELECT p.*, RANK() OVER (ORDER BY total_revenue DESC) AS part_rank
    FROM PartDetails p
    WHERE total_revenue > 0
)
SELECT 
    p.p_name, 
    p.total_revenue, 
    s.s_name AS supplier_name, 
    c.c_mktsegment, 
    coalesce(cust_order_count.total_orders, 0) AS customer_orders
FROM RankedParts p
LEFT JOIN SupplierInfo s ON p.p_partkey = s.s_suppkey
JOIN CustomerSegment c ON c.c_mktsegment = (SELECT c_mktsegment FROM customer WHERE c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MAX(order_key) FROM OrderHierarchy)))
LEFT JOIN CustomerSegment cust_order_count ON c.c_mktsegment = cust_order_count.c_mktsegment
WHERE p.part_rank <= 5
ORDER BY p.total_revenue DESC, supplier_name;
