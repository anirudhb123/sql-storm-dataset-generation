WITH RECURSIVE PartSupply AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost
    FROM partsupp
    WHERE ps_availqty > 10
    UNION ALL
    SELECT p.ps_partkey, p.ps_suppkey, p.ps_availqty - 5, p.ps_supplycost
    FROM partsupp p
    JOIN PartSupply ps ON p.ps_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 5
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderpriority, COUNT(l.l_orderkey) AS lineitem_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderpriority
)
SELECT p.p_partkey, p.p_name, ps.ps_availqty, sd.s_name, sd.nation_name, os.o_totalprice, os.lineitem_count
FROM part p
JOIN PartSupply ps ON p.p_partkey = ps.ps_partkey
JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN OrderStats os ON os.lineitem_count > 5
WHERE p.p_retailprice > 50.00
ORDER BY os.o_totalprice DESC
LIMIT 100;
