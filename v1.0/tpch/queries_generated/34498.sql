WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
MaxTotalPrice AS (
    SELECT MAX(o_totalprice) AS max_price
    FROM orders
)
SELECT p.p_name, 
       COUNT(DISTINCT l.l_orderkey) AS order_count,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
       AVG(sd.total_supply_cost) AS avg_supply_cost,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count,
       ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice) DESC) AS rank
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN OrderHierarchy oh ON l.l_orderkey = oh.o_orderkey
JOIN SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
WHERE p.p_size > 15 AND p.p_retailprice < (SELECT max_price FROM MaxTotalPrice)
GROUP BY p.p_partkey, p.p_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY revenue DESC, p.p_name ASC;
