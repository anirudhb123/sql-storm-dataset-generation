WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) 
                             FROM orders o2 
                             WHERE o2.o_orderstatus = 'F')
), SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT p.p_partkey) AS unique_part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 
           (SELECT AVG(ps_supplycost * ps_availqty) 
            FROM partsupp)
), EffectiveCustomers AS (
    SELECT c.c_custkey, c.c_name, 
           CASE WHEN COUNT(DISTINCT l.l_orderkey) > 5 THEN 'High Value'
                ELSE 'Low Value' END AS customer_value,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, 
       COALESCE(SUM(sd.total_supply_cost), 0) AS total_supply_expense,
       COUNT(DISTINCT ec.c_custkey) AS effective_customer_count,
       MAX(ek.o_totalprice) AS max_order_price
FROM region r
LEFT JOIN (
    SELECT n.n_regionkey, sd.total_supply_cost
    FROM nation n
    LEFT JOIN SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
) AS sd ON r.r_regionkey = sd.n_regionkey
LEFT JOIN EffectiveCustomers ec ON ec.total_spent > 10000
LEFT JOIN RankedOrders ek ON ek.o_orderkey IN
    (SELECT l_orderkey 
     FROM lineitem 
     WHERE l_shipdate IS NOT NULL AND l_commitdate IS NULL)
WHERE r.r_name LIKE 'S%' 
GROUP BY r.r_name
HAVING COUNT(DISTINCT ec.c_custkey) > 3;
