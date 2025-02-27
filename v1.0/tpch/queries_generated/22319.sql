WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 0
),

CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, 
           l.l_quantity, l.l_discount,
           CASE 
               WHEN l.l_returnflag = 'R' THEN 'Returned'
               ELSE 'Not Returned' 
           END AS return_status
    FROM lineitem l
    WHERE l.l_discount > 0.05 
)

SELECT 
    c.c_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT s.s_name, ', ') FILTER (WHERE r.rnk IS NOT NULL) AS top_suppliers,
    MAX(s.s_acctbal) AS highest_supplier_balance
FROM customer c
LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey AND co.order_rank <= 5
LEFT JOIN orders o ON co.c_custkey = o.o_custkey
LEFT JOIN FilteredLineItems l ON o.o_orderkey = l.l_orderkey
LEFT JOIN RankedSuppliers r ON l.l_suppkey = r.s_suppkey
LEFT JOIN supplier s ON r.s_suppkey = s.s_suppkey
WHERE c.c_acctbal IS NOT NULL 
  AND (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
GROUP BY c.c_name
HAVING SUM(l.l_quantity) > 100
   OR COUNT(DISTINCT o.o_orderkey) > 5 
ORDER BY total_revenue DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
