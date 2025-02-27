WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000

    UNION ALL
    
    SELECT ch.c_custkey, ch.c_name, ch.c_acctbal, level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_custkey
    WHERE c.c_acctbal IS NOT NULL AND ch.level < 5
),
FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity,
           l.l_extendedprice * (1 - l.l_discount) AS net_price
    FROM lineitem l
    WHERE l.l_returnflag = 'N' AND l.l_discount BETWEEN 0.05 AND 0.25
),
SuppliersData AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
AggregatedOrders AS (
    SELECT o.o_orderkey, SUM(li.net_price) AS total_net_price,
           COUNT(DISTINCT li.l_partkey) AS part_count
    FROM orders o
    JOIN FilteredLineItems li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    ch.c_name AS customer_name,
    coalesce(ao.part_count, 0) AS order_part_count,
    s.s_name AS supplier_name,
    COALESCE(sd.total_cost, 0) AS supplier_cost,
    SUM(ch.level + ao.total_net_price) AS aggregate_value,
    CASE 
        WHEN SUM(ch.level + ao.total_net_price) > 5000 THEN 'High Value'
        WHEN SUM(ch.level + ao.total_net_price) > 1000 THEN 'Moderate Value'
        ELSE 'Low Value'
    END AS value_category
FROM CustomerHierarchy ch
LEFT JOIN AggregatedOrders ao ON ch.c_custkey = ao.o_orderkey
LEFT JOIN SuppliersData sd ON sd.s_suppkey = (SELECT ps.ps_suppkey 
                                               FROM partsupp ps
                                               WHERE ps.ps_partkey IN 
                                                (SELECT DISTINCT li.l_partkey
                                                 FROM FilteredLineItems li
                                                 JOIN orders o ON li.l_orderkey = o.o_orderkey
                                                 WHERE o.o_orderstatus = 'F')
                                               LIMIT 1)
JOIN supplier s ON s.s_nationkey = ch.c_custkey
GROUP BY ch.c_name, ao.part_count, s.s_name, sd.total_cost
HAVING SUM(ch.level + COALESCE(ao.total_net_price, 0)) IS NOT NULL
ORDER BY aggregate_value DESC
LIMIT 10;
