WITH RECURSIVE OrderHistory AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
),
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, n.n_name AS nation_name,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
),
SupplierPartSummary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
LineItemAggregate AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
           COUNT(*) AS total_line_items, 
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS ln
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT cd.c_name, cd.nation_name, cd.c_acctbal, oh.o_orderkey, oh.o_orderdate,
       la.total_value, la.total_line_items,
       CASE WHEN cd.rank <= 3 THEN 'Top Customer' ELSE 'Regular Customer' END AS customer_status
FROM CustomerDetails cd
LEFT JOIN OrderHistory oh ON cd.c_custkey = oh.o_custkey AND oh.rn = 1
LEFT JOIN LineItemAggregate la ON oh.o_orderkey = la.l_orderkey
LEFT JOIN SupplierPartSummary sps ON la.total_line_items > sps.total_avail_qty
WHERE cd.c_acctbal IS NOT NULL AND cd.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = cd.c_nationkey)
ORDER BY cd.nation_name, cd.c_acctbal DESC
LIMIT 100;
