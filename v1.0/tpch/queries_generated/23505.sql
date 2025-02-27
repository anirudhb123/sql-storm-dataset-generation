WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
MaxPartPrice AS (
    SELECT MAX(p.p_retailprice) AS max_price
    FROM part p
    WHERE p.p_size > 20
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           CASE 
               WHEN COUNT(o.o_orderkey) > 5 THEN 'Frequent Buyer'
               ELSE 'Occasional Buyer'
           END AS buyer_type
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT co.c_name, co.order_count, co.total_spent, rs.s_name, rs.s_acctbal,
       CONCAT('Average Price: ', CAST(AVG(pl.l_extendedprice) OVER (PARTITION BY co.c_custkey) AS VARCHAR)) AS avg_price,
       p.p_name AS popular_part
FROM CustomerOrders co
JOIN RankedSuppliers rs ON co.c_custkey = (CASE
                                               WHEN rs.rnk = 1 THEN 0
                                               ELSE co.c_custkey
                                           END)
LEFT JOIN lineitem pl ON co.c_custkey = pl.l_orderkey
JOIN part p ON pl.l_partkey = p.p_partkey
WHERE co.total_spent > (SELECT COALESCE(AVG(total_spent), 0) FROM CustomerOrders)
  AND p.p_retailprice < (SELECT max_price FROM MaxPartPrice)
  AND rs.s_acctbal IS NOT NULL
ORDER BY co.total_spent DESC, co.c_name ASC;
