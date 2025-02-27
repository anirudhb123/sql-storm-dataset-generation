WITH RankedSuppliers AS (
    SELECT ps.ps_partkey, 
           ps.ps_suppkey, 
           s.s_name, 
           s.s_acctbal,
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 0
),
HighValueOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderstatus, 
           o.o_totalprice,
           o.o_orderdate,
           COUNT(l.l_orderkey) AS total_lines
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_totalprice > 1000
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate
),
CustomerNation AS (
    SELECT c.c_custkey, 
           c.c_name, 
           n.n_name AS nation_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)
SELECT cn.nation_name, 
       SUM(hvo.o_totalprice) AS total_value, 
       COUNT(DISTINCT hvo.o_orderkey) AS number_of_orders, 
       COUNT(DISTINCT rs.supp_key) AS top_suppliers
FROM HighValueOrders hvo
JOIN CustomerNation cn ON (hvo.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey IN (SELECT ps.ps_partkey FROM RankedSuppliers rs WHERE rs.supplier_rank = 1)))
JOIN RankedSuppliers rs ON hvo.o_orderkey = l.l_orderkey
GROUP BY cn.nation_name
HAVING SUM(hvo.o_totalprice) > 50000
ORDER BY total_value DESC;
