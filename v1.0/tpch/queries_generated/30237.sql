WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS depth
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, co.depth + 1
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrders co ON co.c_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate > co.o_orderdate
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
TopProducts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, 
           RANK() OVER (PARTITION BY p.p_brand ORDER BY AVG(l.l_extendedprice * (1 - l.l_discount)) DESC) as product_rank
    FROM lineitem l
    JOIN part p ON l.l_partkey = p.p_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type
),
SupplierWithComments AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s 
    LEFT JOIN PartSupplier ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.total_available < (SELECT AVG(ps_total_total) FROM (SELECT SUM(ps_availqty) AS ps_total_total FROM partsupp GROUP BY ps_partkey) avg_total)
    AND s.s_comment IS NOT NULL
)
SELECT co.c_name, SUM(co.o_totalprice) AS total_spent, 
       COUNT(DISTINCT co.o_orderkey) AS total_orders, 
       STRING_AGG(DISTINCT p.p_name, ', ') AS product_names,
       s.s_name AS supplier_name, s.s_acctbal AS supplier_balance,
       ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY SUM(co.o_totalprice) DESC) AS customer_rank
FROM CustomerOrders co
JOIN TopProducts p ON p.product_rank <= 5
LEFT JOIN SupplierWithComments s ON s.s_suppkey IN (
    SELECT ps.ps_suppkey FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0 
)
WHERE co.depth <= 2
GROUP BY co.c_custkey, co.c_name, s.s_name, s.s_acctbal
HAVING SUM(co.o_totalprice) > 1000
ORDER BY total_spent DESC;
