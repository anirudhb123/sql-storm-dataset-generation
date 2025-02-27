WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT oh.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON oh.o_orderkey = o.o_orderkey
    WHERE o.o_orderdate < oh.o_orderdate
), 
RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_mktsegment, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_mktsegment
    HAVING COUNT(DISTINCT o.o_orderkey) > 5
), 
SuppliersAndParts AS (
    SELECT ps.ps_partkey, s.s_suppkey, s.s_name, 
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_suppkey, s.s_name
), 
FinalReport AS (
    SELECT ch.c_custkey, ch.c_mktsegment, 
           SUM(ch.order_count * rp.p_retailprice) AS total_spending,
           MIN(sap.total_supply_cost) AS min_supply_cost
    FROM CustomerOrders ch
    JOIN RankedParts rp ON ch.order_count > rp.price_rank
    LEFT JOIN SuppliersAndParts sap ON rp.p_partkey = sap.ps_partkey
    GROUP BY ch.c_custkey, ch.c_mktsegment
)

SELECT fr.c_custkey, fr.c_mktsegment, 
       fr.total_spending, fr.min_supply_cost,
       CASE
           WHEN fr.total_spending IS NULL THEN 'No Spending'
           ELSE 'Active Customer'
       END AS customer_status
FROM FinalReport fr
WHERE fr.total_spending > 1000
ORDER BY fr.total_spending DESC, fr.min_supply_cost ASC;
