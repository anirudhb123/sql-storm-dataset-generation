WITH RECURSIVE PartDetails AS (
    SELECT p_partkey, p_name, p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) AS price_rank
    FROM part
),
EligibleSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ps.ps_supplycost, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS cost_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           SUM(o.o_totalprice) AS total_order_price
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING SUM(o.o_totalprice) > 5000
),
RecentLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, 
           DATEDIFF(CURRENT_DATE, l.l_shipdate) AS days_since_ship
    FROM lineitem l
    WHERE l.l_shipdate > DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
)
SELECT pd.p_name, 
       COALESCE(STRING_AGG(DISTINCT es.s_name ORDER BY es.ps_supplycost), 'No Supplier') AS supplier_names,
       COUNT(DISTINCT co.c_custkey) AS customer_count,
       AVG(co.total_order_price) AS avg_order_value,
       SUM(rl.days_since_ship) AS total_days_since_ship,
       CASE 
           WHEN AVG(co.total_order_price) IS NULL THEN 'No Orders'
           ELSE 'Orders Exist'
       END AS order_status
FROM PartDetails pd
LEFT JOIN EligibleSuppliers es ON pd.p_partkey = es.ps_partkey AND es.cost_rank = 1
LEFT JOIN CustomerOrders co ON co.c_custkey = (
    SELECT o.o_custkey
    FROM orders o
    WHERE o.o_orderkey IN (
        SELECT li.l_orderkey
        FROM RecentLineItems li
        WHERE li.l_partkey = pd.p_partkey
    )
    LIMIT 1
)
LEFT JOIN RecentLineItems rl ON rl.l_partkey = pd.p_partkey
WHERE pd.price_rank <= 10 AND pd.p_retailprice IS NOT NULL
GROUP BY pd.p_name
ORDER BY pd.p_name;
