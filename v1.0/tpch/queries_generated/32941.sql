WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
    WHERE o.o_orderstatus = 'O'
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent, MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, cs.total_orders, cs.total_spent
    FROM customer c
    JOIN CustomerSummary cs ON c.c_custkey = cs.c_custkey
    WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSummary)
),
SupplierPartInfo AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name,
           SUM(ps.ps_availqty) AS total_available, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey, p.p_name
),
TopSuppliers AS (
    SELECT s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM lineitem l
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    GROUP BY s.s_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
)
SELECT DISTINCT cs.c_name, cs.total_orders, cs.total_spent, 
       COALESCE(sp.total_available, 0) AS total_available_parts,
       COALESCE(ss.total_sales, 0) AS supplier_total_sales
FROM CustomerSummary cs
LEFT JOIN SupplierPartInfo sp ON cs.c_custkey = sp.s_suppkey
LEFT JOIN TopSuppliers ss ON ss.s_name = cs.c_name
WHERE cs.total_orders > 5 AND cs.last_order_date > CURRENT_DATE - INTERVAL '1 year'
ORDER BY cs.total_spent DESC
LIMIT 10;
