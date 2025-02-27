WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice 
    FROM customer c 
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2022-01-01'
    UNION ALL
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice 
    FROM customer c 
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrders co ON co.o_orderkey = o.o_orderkey
)
, RankedPrices AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        SUM(co.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY co.c_custkey ORDER BY SUM(co.o_totalprice) DESC) AS price_rank
    FROM CustomerOrders co
    GROUP BY co.c_custkey, co.c_name
)
SELECT 
    c.c_custkey,
    c.c_name,
    r.total_spent,
    CASE 
        WHEN r.price_rank = 1 THEN 'Top Spender'
        ELSE 'Regular Spender'
    END AS spender_category
FROM customer c
LEFT JOIN RankedPrices r ON c.c_custkey = r.c_custkey
WHERE r.total_spent IS NOT NULL
AND EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.o_custkey = c.c_custkey AND o.o_orderstatus = 'O'
)
ORDER BY r.total_spent DESC
LIMIT 10;

SELECT DISTINCT p.p_brand, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
WHERE p.p_size IN (SELECT p_size FROM part WHERE p_type LIKE '%plastic%')
GROUP BY p.p_brand, p.p_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY revenue DESC;

SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nations_count,
    SUM(COALESCE(s.s_acctbal, 0)) AS total_account_balance,
    MAX(s.s_acctbal) AS highest_account_balance,
    MIN(s.s_acctbal) AS lowest_account_balance
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
GROUP BY r.r_name
HAVING total_account_balance > 50000
ORDER BY nations_count DESC, r.r_name;
