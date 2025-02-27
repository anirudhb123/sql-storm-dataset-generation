WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, c_nationkey, 1 AS level
    FROM customer
    WHERE c_acctbal > 5000

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, h.level + 1
    FROM customer c
    JOIN CustomerHierarchy h ON c.c_nationkey = h.c_nationkey AND c.custkey <> h.c_custkey
    WHERE c.c_acctbal BETWEEN 1000 AND 5000
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, s.s_name, SUM(ps.ps_availqty) AS total_avail_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr, s.s_name
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
)
SELECT ch.c_name, p.p_name, p.total_avail_qty, os.o_totalprice,
   CASE 
       WHEN os.rnk = 1 THEN 'Top Order' 
       ELSE 'Regular Order' 
   END AS order_rank
FROM CustomerHierarchy ch
LEFT JOIN PartSupplierDetails p ON ch.c_nationkey = (
    SELECT n.n_nationkey 
    FROM nation n 
    WHERE n.n_name = 'UNITED STATES'
)
INNER JOIN OrderStats os ON os.o_orderkey = (
    SELECT l.l_orderkey 
    FROM lineitem l 
    WHERE l.l_partkey IN (SELECT p.p_partkey FROM PartSupplierDetails p WHERE p.total_avail_qty IS NOT NULL)
)
WHERE p.total_avail_qty > 0 AND ch.level = 2
ORDER BY ch.c_name, p.total_avail_qty DESC;
