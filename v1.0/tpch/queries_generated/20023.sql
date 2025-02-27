WITH RECURSIVE CustomerRank AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
), PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           (SELECT COUNT(DISTINCT ps.s_suppkey) 
            FROM partsupp ps 
            WHERE ps.ps_partkey = p.p_partkey) AS supplier_count
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
), NationalOrders AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM nation n
    LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
    LEFT JOIN orders o ON o.o_custkey = c.c_custkey
    GROUP BY n.n_nationkey, n.n_name
), EnhancedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, 
           l.l_discount, l.l_returnflag, l.l_linestatus,
           CASE 
               WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount)
               ELSE l.l_extendedprice
           END AS price_after_discount
    FROM lineitem l
    WHERE l.l_returnflag = 'N' 
), OrderSummary AS (
    SELECT o.o_orderkey, COUNT(li.l_orderkey) AS lineitem_count,
           SUM(li.price_after_discount) AS total_lineitem_value
    FROM orders o
    JOIN EnhancedLineItems li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT c.c_name, r.r_name, n.order_count, n.total_spent, pr.supplier_count,
       COALESCE(AVG(es.total_lineitem_value), 0) AS avg_order_value,
       CASE 
           WHEN n.total_spent > 10000 THEN 'High Value'
           WHEN n.total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_category
FROM NationalOrders n
JOIN region r ON n.n_nationkey = r.r_regionkey
JOIN CustomerRank c ON c.rank = 1
JOIN PartDetails pr ON pr.supplier_count > n.order_count
LEFT JOIN OrderSummary es ON n.order_count = es.lineitem_count
WHERE r.r_name LIKE 'E%'
GROUP BY c.c_name, r.r_name, n.order_count, n.total_spent, pr.supplier_count
HAVING COUNT(c.c_custkey) > 0 
ORDER BY avg_order_value DESC, customer_category;
