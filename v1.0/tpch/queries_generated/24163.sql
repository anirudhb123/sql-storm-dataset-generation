WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
CostlyParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS PriceRank
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
HighVolumeOrders AS (
    SELECT o.o_orderkey, SUM(l.l_quantity) AS TotalQuantity,
           MAX(l.l_extendedprice) AS MaxExtendedPrice
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_quantity) > 100
),
SupplierAvailability AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS TotalAvailable
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
SelectedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, COALESCE(ps.TotalAvailable, 0) AS AvailableQty
    FROM part p
    LEFT JOIN SupplierAvailability ps ON p.p_partkey = ps.ps_partkey
)
SELECT DISTINCT
    r.r_name AS Region,
    n.n_name AS Nation,
    s.s_name AS Supplier,
    sp.p_name AS PartName,
    sp.AvailableQty,
    COALESCE(sp.AvailableQty, 0) + COALESCE(rsp.p_retailprice, 0) AS AdjustedInfo,
    CASE 
        WHEN rsp.SupplierRank < 10 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS SupplierCategory
FROM RankedSuppliers rsp
JOIN nation n ON rsp.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN SelectedParts sp ON rsp.s_suppkey IN (
    SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = sp.p_partkey
) 
WHERE sp.AvailableQty > 0
OR sp.p_retailprice IS NULL
ORDER BY r.r_name, n.n_name, rsp.SupplierRank
LIMIT 100 OFFSET 50;
