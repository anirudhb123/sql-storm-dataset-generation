
WITH RECURSIVE RankedParts AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_retailprice, 0 AS rank
    FROM part
    WHERE p_size > 0
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_retailprice, rp.rank + 1
    FROM part p
    JOIN RankedParts rp ON p.p_size = rp.p_size + 1
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT r.r_name, 
       COUNT(DISTINCT n.n_nationkey) AS nation_count,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
       COALESCE(cus.total_spent, 0) AS customer_total_spent,
       (SELECT COUNT(DISTINCT l_orderkey) 
        FROM lineitem 
        WHERE l_shipmode = 'AIR' 
          AND l_returnflag = 'R') AS air_returned_count,
       ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN CustomerOrderSummary cus ON s.s_suppkey = cus.c_custkey
LEFT JOIN PartSupplierInfo psi ON l.l_partkey = psi.ps_partkey
WHERE l.l_shipdate >= '1997-01-01'
  AND l.l_shipdate < '1997-10-01'
GROUP BY r.r_name, cus.total_spent
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY sales_rank DESC NULLS LAST;
