WITH RecursiveCTE AS (
    SELECT p_partkey, p_name, p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) as rn
    FROM part
    WHERE p_size IN (SELECT DISTINCT CASE 
                                         WHEN p_size % 2 = 0 THEN p_size 
                                         ELSE NULL 
                                     END 
                     FROM part)
), RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) OVER (PARTITION BY s.s_suppkey) AS total_supply_cost,
           RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) as supplier_rank
    FROM supplier s 
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
), LineItemAggregate AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM lineitem l 
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, COUNT(o.o_orderkey) AS order_count,
           COALESCE(SUM(lo.total_price), 0) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN LineItemAggregate lo ON o.o_orderkey = lo.l_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT RCTE.p_partkey, RCTE.p_name, 
       COALESCE(cust.total_spent, 0) AS total_spent,
       RANK() OVER (ORDER BY COALESCE(cust.total_spent, 0) DESC) AS customer_rank,
       RS.total_supply_cost
FROM RecursiveCTE RCTE
LEFT JOIN CustomerOrders cust ON cust.order_count > 0
JOIN RankedSuppliers RS ON RS.supplier_rank <= 5 
WHERE RCTE.rn = 1 
  AND RCTE.p_retailprice > (SELECT AVG(p_retailprice) FROM part WHERE p_container IS NOT NULL)
  AND (RS.total_supply_cost IS NOT NULL OR RS.total_supply_cost < RCTE.p_retailprice / 2)
ORDER BY RS.total_supply_cost DESC, cust.total_spent DESC
LIMIT 100;
