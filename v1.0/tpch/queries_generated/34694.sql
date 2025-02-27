WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
LineItemStats AS (
    SELECT l.suppkey,
           COUNT(*) AS total_items,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           AVG(l.l_quantity) AS avg_quantity,
           MIN(l.l_tax) AS min_tax,
           MAX(l.l_tax) AS max_tax
    FROM lineitem l
    GROUP BY l.suppkey
),
CustomerSummary AS (
    SELECT c.c_custkey,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY c.c_custkey
)
SELECT 
    oh.o_orderkey,
    c.c_name,
    r.r_name AS region,
    li.total_revenue,
    sd.total_cost,
    cs.total_spent,
    DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY cs.total_spent DESC) AS spending_rank,
    CASE 
        WHEN c.c_acctbal IS NULL THEN 'Account Balance Not Available'
        WHEN c.c_acctbal < 1000 THEN 'Low Balance'
        ELSE 'Sufficient Balance'
    END AS balance_status
FROM OrderHierarchy oh
JOIN customer c ON oh.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN LineItemStats li ON li.suppkey = oh.o_orderkey -- Using outer join to include orders with no line items
JOIN SupplierDetails sd ON sd.s_suppkey = li.suppkey
JOIN CustomerSummary cs ON cs.c_custkey = oh.o_custkey
WHERE oh.level <= 5
ORDER BY oh.o_orderkey, spending_rank DESC
LIMIT 100;
