WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal
    FROM customer
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_nationkey IS NOT NULL)
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal < ch.c_acctbal
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    ch.c_name, ch.c_acctbal, s.s_name, sd.total_avail_qty, 
    CASE 
        WHEN ch.c_acctbal IS NULL THEN 'No Account Balance'
        ELSE CASE 
            WHEN ch.c_acctbal < 1000 THEN 'Low Balance' 
            ELSE 'Sufficient Balance' 
        END 
    END AS balance_status,
    STRING_AGG(DISTINCT (CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned' 
        ELSE 'Not Returned' 
    END), ', ') AS return_status
FROM CustomerHierarchy ch
LEFT JOIN RecentOrders ro ON ch.c_custkey = ro.o_custkey AND ro.order_rank = 1
LEFT JOIN lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN SupplierDetails sd ON sd.total_avail_qty > (
    SELECT AVG(total_avail_qty) FROM SupplierDetails
)
JOIN nation n ON ch.c_nationkey = n.n_nationkey
WHERE 
    (n.n_name LIKE '%land%' AND n.n_name NOT LIKE '%Wonderland%')
    OR n.n_comment IS NOT NULL
GROUP BY ch.c_name, ch.c_acctbal, s.s_name, sd.total_avail_qty
ORDER BY ch.c_acctbal DESC, s.s_name;
