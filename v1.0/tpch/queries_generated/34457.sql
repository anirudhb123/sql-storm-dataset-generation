WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
)
, TotalCost AS (
    SELECT
        p.p_partkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supplier_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
    GROUP BY p.p_partkey
),
RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
CustomerSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 0
)
SELECT
    c.c_name AS customer_name,
    cs.order_count,
    cs.total_spent,
    th.total_supplier_cost,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Spending'
        ELSE 'Regular Customer'
    END AS customer_status
FROM CustomerSummary cs
LEFT JOIN TotalCost th ON cs.order_count = th.p_partkey  -- assuming order_count corresponds to partkey
LEFT JOIN SupplierHierarchy sh ON cs.total_spent > 1000  -- use arbitrary threshold for filtering
WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSummary)
ORDER BY cs.total_spent DESC, customer_name;
