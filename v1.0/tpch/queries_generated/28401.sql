WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, p.p_comment
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
OrderCount AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS total_orders
    FROM orders o
    GROUP BY o.o_custkey
),
SupplierInfo AS (
    SELECT rs.s_suppkey, rs.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM RankedSuppliers rs
    JOIN partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    GROUP BY rs.s_suppkey, rs.s_name
)
SELECT c.c_name, c.c_address, c.c_phone, rs.s_name AS supplier_name, f.p_name AS part_name,
       s.total_orders, si.part_count, 
       CONCAT('Customer: ', c.c_name, ', Supplier: ', rs.s_name, ', Part: ', f.p_name) AS composite_info
FROM customer c
JOIN OrderCount s ON c.c_custkey = s.o_custkey
JOIN RankedSuppliers rs ON c.c_nationkey = rs.s_suppkey
JOIN FilteredParts f ON f.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey)
JOIN SupplierInfo si ON rs.s_suppkey = si.s_suppkey
WHERE rs.rank = 1
ORDER BY s.total_orders DESC, si.part_count DESC
LIMIT 10;
