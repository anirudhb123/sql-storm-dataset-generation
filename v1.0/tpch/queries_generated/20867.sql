WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) as rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal IS NOT NULL
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           CASE 
               WHEN c.c_acctbal > 5000 THEN 'VIP'
               WHEN c.c_acctbal BETWEEN 1000 AND 5000 THEN 'Regular'
               ELSE 'Low-value'
           END AS cust_type
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
OrderStats AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS orders_count, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
DiscountedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_extendedprice,
           CASE 
               WHEN l.l_discount > 0.2 THEN l.l_extendedprice * (1 - l.l_discount)
               ELSE l.l_extendedprice
           END AS discounted_price
    FROM lineitem l
    WHERE l.l_discount IS NOT NULL
),
FinalResults AS (
    SELECT c.c_name AS customer_name, s.s_name AS supplier_name,
           SUM(d.discounted_price) AS total_discount,
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           (SELECT COUNT(*) FROM RankedSuppliers rs WHERE rs.rnk = 1) AS top_supplier_count
    FROM HighValueCustomers c
    LEFT JOIN OrderStats os ON c.c_custkey = os.o_custkey
    LEFT JOIN lineitem l ON os.o_custkey = l.l_orderkey
    LEFT JOIN DiscountedLineItems d ON l.l_orderkey = d.l_orderkey
    LEFT JOIN supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey
                                            FROM partsupp ps
                                            JOIN part p ON ps.ps_partkey = p.p_partkey
                                            WHERE p.p_size = (SELECT MAX(p2.p_size) FROM part p2))
    )
    WHERE c.c_acctbal > 1000
    GROUP BY c.c_name, s.s_name
)

SELECT *,
       CASE 
           WHEN total_discount IS NULL THEN 'No discounts applied'
           WHEN total_discount > 1000 THEN 'High discount status'
           ELSE 'Regular discount status'
       END AS discount_status
FROM FinalResults
WHERE total_orders > 0
OR total_discount IS NOT NULL
ORDER BY total_discount DESC, customer_name ASC;
