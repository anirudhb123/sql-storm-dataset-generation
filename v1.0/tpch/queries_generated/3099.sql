WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as acct_rank
    FROM supplier s
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           CASE 
               WHEN p.p_retailprice > 100 THEN 'High'
               WHEN p.p_retailprice BETWEEN 50 AND 100 THEN 'Medium'
               ELSE 'Low'
           END AS value_category
    FROM part p
    WHERE p.p_size IN (5, 10, 15)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) as total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
SupplierPartAvailability AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           COALESCE(SUM(l.l_quantity), 0) AS total_sold
    FROM partsupp ps
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost
)
SELECT o.c_custkey, o.c_name, s.s_name, p.p_name, p.value_category,
       sa.ps_availqty, sa.total_sold, 
       (sa.ps_supplycost - AVG(sa.ps_supplycost) OVER ()) AS cost_diff, 
       ROW_NUMBER() OVER (PARTITION BY o.c_custkey ORDER BY total_spent DESC) as order_rank
FROM CustomerOrders o
JOIN RankedSuppliers s ON o.c_custkey % 5 = s.s_nationkey % 5
JOIN HighValueParts p ON o.total_spent > 500 AND p.p_partkey IN
    (SELECT ps.ps_partkey FROM SupplierPartAvailability ps 
     WHERE ps.ps_availqty > 0)
LEFT JOIN SupplierPartAvailability sa ON p.p_partkey = sa.ps_partkey
WHERE s.acct_rank <= 3
ORDER BY o.c_custkey, p.value_category DESC, o.o_orderdate DESC;
