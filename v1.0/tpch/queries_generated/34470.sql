WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS lvl
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT oh.o_orderkey, o.o_orderdate, o.o_totalprice, oh.lvl + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
SupplierStats AS (
    SELECT s.s_suppkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
PartSummary AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CustomerSummary AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_line_value
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    ps.supplier_count,
    ps.total_value,
    cs.order_count,
    cs.total_spent,
    oh.o_orderdate,
    oh.o_totalprice,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY total_value DESC) as rn1,
    RANK() OVER (ORDER BY cs.total_spent DESC) AS rank_by_spending
FROM PartSummary ps
JOIN CustomerSummary cs ON ps.supplier_count > 5
LEFT JOIN OrderDetails od ON ps.p_partkey = od.o_orderkey
JOIN OrderHierarchy oh ON od.o_orderkey = oh.o_orderkey
WHERE ps.total_value IS NOT NULL AND cs.order_count > 10
ORDER BY total_value DESC, cs.total_spent DESC
LIMIT 25;
