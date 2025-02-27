WITH RECURSIVE CustOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustOrders co ON c.c_custkey = co.c_custkey
    WHERE o.o_orderdate > co.o_orderdate
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost, 
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
SuppliersWithNulls AS (
    SELECT s.s_suppkey, s.s_name, s.s_addr, s.s_acctbal, s.s_comment,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC NULLS LAST) AS rank_with_nulls
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
)
SELECT co.c_custkey, co.c_name, 
       COUNT(DISTINCT co.o_orderkey) AS total_orders,
       SUM(co.o_totalprice) AS total_spent,
       rp.p_name AS part_name,
       sp.s_name AS supplier_name,
       sp.rank_with_nulls AS supplier_rank
FROM CustOrders co
LEFT JOIN RankedParts rp ON co.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = rp.p_partkey)
LEFT JOIN SuppliersWithNulls sp ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sp.s_suppkey)
WHERE co.total_spent > (SELECT AVG(o.o_totalprice) FROM orders o WHERE o.o_orderstatus = 'O')
GROUP BY co.c_custkey, co.c_name, rp.p_name, sp.s_name, sp.rank_with_nulls
ORDER BY total_spent DESC, part_name ASC
LIMIT 50;
