WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone, 
           s.s_acctbal, s.s_comment, 
           n.n_name AS NationName, 
           r.r_name AS RegionName
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, 
           p.p_retailprice, p.p_comment
    FROM part p
    WHERE p.p_retailprice > 100.00
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, 
           COUNT(l.l_orderkey) AS LineItemCount
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name
)
SELECT 
    si.s_name AS SupplierName,
    si.NationName,
    si.RegionName,
    pi.p_name AS PartName,
    os.o_orderkey AS OrderKey,
    os.o_orderdate AS OrderDate,
    os.o_totalprice AS TotalPrice,
    os.LineItemCount AS LineItemCount,
    CONCAT(si.s_name, ' from ', si.NationName, ' Supplies ', pi.p_name) AS SupplierPartInfo
FROM SupplierInfo si
JOIN partsupp ps ON si.s_suppkey = ps.ps_suppkey
JOIN PartInfo pi ON ps.ps_partkey = pi.p_partkey
JOIN OrderSummary os ON os.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_partkey = pi.p_partkey
)
WHERE si.s_acctbal > 50000
ORDER BY si.NationName, os.o_orderdate DESC;
