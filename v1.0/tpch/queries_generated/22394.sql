WITH RECURSIVE CustomerSales AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY c.c_custkey, c.c_name

    UNION ALL

    SELECT cs.c_custkey, cs.c_name, cs.total_spent * 1.1
    FROM CustomerSales cs
    WHERE cs.total_spent IS NOT NULL
),

HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, cs.total_spent, 
           ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS sales_rank
    FROM customer c
    JOIN CustomerSales cs ON c.c_custkey = cs.c_custkey
    WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
),

SupplierCosts AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
    GROUP BY ps.ps_suppkey
),

LineItemAggregates AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue_after_discount,
           COUNT(l.l_linenumber) AS item_count,
           MAX(l.l_shipdate) AS last_ship_date
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT h.c_name, h.total_spent,
       COALESCE(l.item_count, 0) AS total_items_ordered,
       COALESCE(s.total_cost, 0) AS supplier_cost,
       CASE 
           WHEN h.total_spent > 10000 THEN 'Platinum'
           WHEN h.total_spent BETWEEN 5000 AND 10000 THEN 'Gold'
           ELSE 'Silver' 
       END AS customer_tier,
       ROW_NUMBER() OVER (PARTITION BY customer_tier ORDER BY h.total_spent DESC) AS tier_rank
FROM HighValueCustomers h
LEFT JOIN LineItemAggregates l ON h.c_custkey = l.l_orderkey 
LEFT JOIN SupplierCosts s ON l.l_orderkey = s.ps_suppkey
WHERE h.sales_rank <= 10
ORDER BY h.total_spent DESC, customer_tier DESC
LIMIT 20;
