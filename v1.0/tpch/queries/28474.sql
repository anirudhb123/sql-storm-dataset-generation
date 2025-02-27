WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_phone, p.p_name, ps.ps_availqty, ps.ps_supplycost, 
           CONCAT('Supplier: ', s.s_name, ', Address: ', s.s_address, ', Phone: ', s.s_phone) AS SupplierInfo,
           CONCAT('Part: ', p.p_name, ', Quantity Available: ', ps.ps_availqty, ', Supply Cost: $', ps.ps_supplycost) AS PartInfo
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), AggregatedSupplier AS (
    SELECT COUNT(DISTINCT s_suppkey) AS SupplierCount, 
           SUM(ps_supplycost) AS TotalSupplyCost,
           STRING_AGG(DISTINCT SupplierInfo, '; ') AS AllSuppliers,
           STRING_AGG(DISTINCT PartInfo, '; ') AS AllParts
    FROM SupplierDetails
)
SELECT SupplierCount, TotalSupplyCost, AllSuppliers, AllParts
FROM AggregatedSupplier
WHERE TotalSupplyCost > 10000.00;
