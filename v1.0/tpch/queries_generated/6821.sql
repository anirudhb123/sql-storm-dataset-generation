WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_retailprice, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
OrderDetails AS (
    SELECT o.o_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity, l.l_extendedprice, l.l_discount, l.l_tax
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
),
CustomerInfo AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, c.c_mktsegment
    FROM customer c
)
SELECT c.c_name,
       SUM(l.l_quantity) AS total_quantity,
       SUM(l.l_extendedprice) AS total_revenue,
       AVG(p.ps_supplycost) AS avg_supply_cost,
       MAX(p.p_retailprice) AS max_price,
       COUNT(DISTINCT l.l_orderkey) AS total_orders
FROM CustomerInfo c
JOIN OrderDetails l ON c.c_custkey = l.l_orderkey
JOIN SupplierParts p ON l.l_suppkey = p.s_suppkey AND l.l_partkey = p.p_partkey
WHERE c.c_mktsegment = 'BUILDING'
GROUP BY c.c_name
HAVING SUM(l.l_extendedprice) > 10000
ORDER BY total_revenue DESC
LIMIT 10;
