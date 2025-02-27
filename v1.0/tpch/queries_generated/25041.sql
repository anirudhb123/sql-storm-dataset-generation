WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name, s.s_acctbal, s.s_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, 
           p.p_retailprice, p.p_comment, ps.ps_availqty, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           o.o_orderdate, c.c_name AS customer_name, c.c_mktsegment
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate, c.c_name, c.c_mktsegment
)
SELECT sd.nation_name, COUNT(DISTINCT sd.s_suppkey) AS total_suppliers, 
       COUNT(DISTINCT od.o_orderkey) AS total_orders,
       MAX(pd.p_retailprice) AS max_part_price, 
       MIN(pd.p_retailprice) AS min_part_price,
       AVG(pd.p_retailprice) AS avg_part_price, 
       STRING_AGG(DISTINCT pd.p_brand, ', ') AS unique_brands
FROM SupplierDetails sd
JOIN PartDetails pd ON pd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
JOIN OrderDetails od ON od.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = sd.n_suppkey)
WHERE sd.s_acctbal > 1000
GROUP BY sd.nation_name
ORDER BY sd.nation_name;
