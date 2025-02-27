WITH RECURSIVE HighValueSuppliers AS (
    SELECT s_suppkey, s_name, s_acctbal
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    JOIN HighValueSuppliers hvs ON s.s_acctbal > hvs.s_acctbal * 1.1
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost) AS total_supply_cost, AVG(ps.ps_availqty) AS avg_avail_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),
PopularParts AS (
    SELECT line.l_partkey, COUNT(line.l_orderkey) AS order_count
    FROM lineitem line
    GROUP BY line.l_partkey
    HAVING COUNT(line.l_orderkey) > 10
)
SELECT 
    c.c_name AS customer_name,
    SUM(o.o_totalprice) AS total_order_value,
    p.p_name AS popular_part,
    avg_part.avg_avail_qty,
    s.s_name AS supplier_name,
    hvs.s_acctbal AS supplier_acct_balance,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN PopularParts pp ON pp.l_partkey = ANY(ARRAY(SELECT l.l_partkey 
                                                  FROM lineitem l 
                                                  WHERE l.l_orderkey = o.o_orderkey))
JOIN PartSupplierInfo avg_part ON avg_part.p_partkey = pp.l_partkey
JOIN partsupp ps ON avg_part.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN HighValueSuppliers hvs ON hvs.s_suppkey = s.s_suppkey
WHERE c.c_acctbal IS NOT NULL
GROUP BY c.c_name, p.p_name, avg_part.avg_avail_qty, s.s_name, hvs.s_acctbal
ORDER BY total_order_value DESC
LIMIT 10;
