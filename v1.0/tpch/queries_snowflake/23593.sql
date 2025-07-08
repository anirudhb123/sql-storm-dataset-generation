WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM orders o
    WHERE o.o_orderdate >= (cast('1998-10-01' as date) - INTERVAL '2 year')
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           CASE 
               WHEN s.s_acctbal IS NULL THEN 'Unknown'
               WHEN s.s_acctbal < 100.00 THEN 'Low Balance'
               ELSE 'Sufficient Balance'
           END AS AccountStatus
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS TotalAvailable, 
           AVG(ps.ps_supplycost) AS AverageCost,
           COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopPartSuppliers AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY COALESCE(ps.TotalAvailable, 0) DESC) AS BrandRank
    FROM part p
    LEFT JOIN PartSupplierStats ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
FinalReport AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, 
           rd.s_name AS SupplierName, rd.AccountStatus,
           ts.p_name AS PartName, ts.BrandRank
    FROM RankedOrders o
    JOIN SupplierDetails rd ON rd.s_suppkey IN (SELECT l.l_suppkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
    JOIN TopPartSuppliers ts ON ts.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
    WHERE o.o_totalprice < 1000.00 OR o.o_orderstatus = 'F'
)
SELECT f.o_orderkey, f.o_orderstatus, f.o_totalprice, 
       CONCAT('Supplier: ', f.SupplierName, ' (', f.AccountStatus, ')') AS SupplierInformation,
       CONCAT('Part: ', f.PartName, ' - Brand Rank: ', f.BrandRank) AS PartDetails
FROM FinalReport f
ORDER BY f.o_totalprice DESC, f.o_orderstatus, f.SupplierName;