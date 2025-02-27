WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
),
SupplierPartDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           p.p_brand, p.p_type,
           (CASE 
               WHEN p.p_size IS NULL THEN 'Unknown size' 
               ELSE CAST(p.p_size AS varchar)
           END) AS size_description
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
FilteredSupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           COALESCE(NULLIF(s.s_comment, ''), 'No comments available') AS sanitized_comment
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) 
                         FROM supplier s2 
                         WHERE s2.s_acctbal IS NOT NULL)
)
SELECT c.c_name, c.total_orders, c.total_spent,
       COALESCE(SUM(spd.ps_supplycost * spd.ps_availqty), 0) AS total_costs,
       COUNT(DISTINCT rs.o_orderkey) AS unique_orders_ranked,
       STRING_AGG(DISTINCT spd.size_description, ', ') AS available_sizes,
       MAX(MAX(spd.ps_supplycost)) OVER () AS max_supplycost,
       CASE 
           WHEN c.total_spent > 10000 THEN 'High spender'
           WHEN c.total_spent IS NULL THEN 'No transactions'
           ELSE 'Regular customer' 
       END AS customer_segment
FROM CustomerOrderSummary c
LEFT JOIN SupplierPartDetails spd ON c.c_custkey = (SELECT o.o_custkey FROM RankedOrders rs WHERE rs.o_orderkey = spd.ps_partkey) 
LEFT JOIN RankedOrders rs ON c.total_orders > rs.rn
LEFT JOIN FilteredSupplierDetails fsd ON spd.ps_suppkey = fsd.s_suppkey
GROUP BY c.c_name, c.total_orders, c.total_spent
HAVING COUNT(DISTINCT rs.o_orderkey) > 1 
   OR COALESCE(SUM(spd.ps_supplycost * spd.ps_availqty), 0) > 5000
ORDER BY c.total_spent DESC NULLS LAST;
