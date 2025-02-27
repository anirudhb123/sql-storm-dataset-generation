WITH FilteredParts AS (
    SELECT p_partkey, p_name, p_brand, p_type, p_retailprice
    FROM part
    WHERE p_size BETWEEN 10 AND 50 AND p_retailprice > 100.00
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           n.n_name AS nation_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, n.n_name, s.s_acctbal
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 20000
),
OrderDetails AS (
    SELECT o.o_orderkey, c.c_name, o.o_orderdate, o.o_totalprice,
           SUM(l.l_quantity) AS total_quantity, 
           STRING_AGG(DISTINCT CONCAT(l.l_linenumber, ':', l.l_partkey) ORDER BY l.l_linenumber) AS line_items
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 500.00
    GROUP BY o.o_orderkey, c.c_name, o.o_orderdate, o.o_totalprice
),
FinalBenchmark AS (
    SELECT fp.p_partkey, fp.p_name, fp.p_brand, sd.s_name, sd.nation_name,
           od.total_quantity, od.line_items
    FROM FilteredParts fp
    JOIN SupplierDetails sd ON fp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = sd.total_cost LIMIT 1)
    JOIN OrderDetails od ON od.total_quantity > 100
)
SELECT *
FROM FinalBenchmark
ORDER BY p_partkey, total_quantity DESC;
