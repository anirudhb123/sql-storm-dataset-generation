WITH RECURSIVE CustomerStatus AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           CASE WHEN c.c_acctbal IS NULL THEN 'UNKNOWN'
                WHEN c.c_acctbal < 0 THEN 'DEBT'
                ELSE 'CREDIT' END AS acct_status
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
    UNION ALL
    SELECT cs.c_custkey, cs.c_name, cs.c_acctbal,
           CASE WHEN cs.c_acctbal < 0 THEN 'DEBT'
                ELSE 'CREDIT' END AS acct_status
    FROM CustomerStatus cs
    JOIN customer c ON cs.c_custkey = c.c_custkey
    WHERE cs.acct_status = 'CREDIT' AND c.c_acctbal < cs.c_acctbal
),
SupplierPartInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, oi.l_partkey, oi.l_quantity,
           oi.l_extendedprice, oi.l_discount, oi.l_tax,
           DENSE_RANK() OVER (PARTITION BY o.o_orderkey ORDER BY oi.l_quantity DESC) AS item_rank
    FROM orders o
    JOIN lineitem oi ON o.o_orderkey = oi.l_orderkey
)
SELECT cs.c_name, cs.acct_status, SUM(oi.l_extendedprice * (1 - oi.l_discount)) AS total_order_amount,
       MAX(s.s_name) AS supplier_name, COUNT(DISTINCT oi.l_partkey) AS unique_parts
FROM CustomerStatus cs
LEFT JOIN OrderDetails oi ON cs.c_custkey = oi.o_orderkey
LEFT JOIN SupplierPartInfo s ON oi.l_partkey = s.p_partkey AND s.supplier_rank = 1
JOIN HighValueCustomers hc ON cs.c_custkey = hc.c_custkey
WHERE oi.l_quantity > 0
AND cs.acct_status IS NOT NULL
GROUP BY cs.c_name, cs.acct_status
HAVING total_order_amount > (SELECT AVG(total_spent) FROM HighValueCustomers) OR
       COUNT(DISTINCT oi.l_partkey) > (SELECT COUNT(DISTINCT p.p_partkey) FROM part p) / 2
ORDER BY total_order_amount DESC, cs.c_name ASC
LIMIT 10;
