WITH RECURSIVE SupplierRanking AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           s.s_nationkey, 
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
TopSuppliers AS (
    SELECT sr.s_suppkey, 
           sr.s_name, 
           sr.s_acctbal, 
           n.n_name
    FROM SupplierRanking sr
    JOIN nation n ON sr.s_nationkey = n.n_nationkey
    WHERE sr.rank <= 5
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
),
OrdersWithLineItems AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
SupplierStats AS (
    SELECT ps.ps_partkey, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
           SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, 
           c.c_name,
           CASE 
               WHEN c.c_acctbal > 1000 THEN 'Premium'
               WHEN c.c_acctbal BETWEEN 500 AND 1000 THEN 'Standard'
               ELSE 'Basic'
           END AS customer_tier
    FROM customer c
),
CombinedResults AS (
    SELECT co.c_custkey, 
           co.c_name, 
           co.total_spent, 
           n.n_name AS supplier_nation,
           ss.supplier_count,
           ss.total_supplycost,
           hvc.customer_tier
    FROM CustomerOrders co
    JOIN TopSuppliers ts ON ts.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT DISTINCT l.l_partkey 
            FROM lineitem l 
            JOIN orders o ON l.l_orderkey = o.o_orderkey 
            WHERE o.o_orderstatus = 'O'
        )
    )
    JOIN nation n ON ts.s_nationkey = n.n_nationkey
    JOIN SupplierStats ss ON ss.ps_partkey IN (
        SELECT p.p_partkey 
        FROM part p 
        WHERE p.p_size IS NOT NULL
    )
    JOIN HighValueCustomers hvc ON co.c_custkey = hvc.c_custkey
)
SELECT DISTINCT cr.c_name,
       cr.total_spent,
       cr.supplier_count,
       cr.total_supplycost,
       cr.customer_tier,
       COALESCE((SELECT AVG(cr2.total_spent) 
                 FROM CombinedResults cr2 
                 WHERE cr2.supplier_count > cr.supplier_count), 0) AS avg_spent_of_higher_supplier_count
FROM CombinedResults cr
WHERE cr.total_spent > (
    SELECT AVG(cov.total_spent) 
    FROM CombinedResults cov 
    WHERE cov.customer_tier = 'Premium'
)
ORDER BY cr.total_spent DESC;
