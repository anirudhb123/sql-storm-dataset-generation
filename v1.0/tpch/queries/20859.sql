
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        o.o_custkey
    FROM orders o
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31' 
      AND o.o_orderstatus IN ('O', 'F')
),
CustomerWithHighValueOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN FilteredOrders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
PartSupplierDetails AS (
    SELECT 
        p.p_name,
        p.p_brand,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 50.00)
    GROUP BY p.p_name, p.p_brand
)
SELECT 
    c.c_name AS CustomerName,
    SUM(fo.o_totalprice) AS TotalOrderValue,
    psd.p_name AS PartName,
    psd.avg_supply_cost AS AverageSupplyCost,
    COALESCE(rs.s_name, 'No Supplier') AS SupplierName,
    rs.s_acctbal
FROM CustomerWithHighValueOrders c
LEFT JOIN FilteredOrders fo ON c.c_custkey = fo.o_custkey
LEFT JOIN PartSupplierDetails psd ON psd.p_name LIKE '%Widget%'
LEFT JOIN RankedSuppliers rs ON rs.s_suppkey = (
    SELECT s.s_suppkey 
    FROM RankedSuppliers s 
    WHERE s.s_suppkey = c.c_custkey AND s.s_acctbal > 0 
    ORDER BY s.supplier_rank ASC 
    LIMIT 1
)
GROUP BY c.c_name, psd.p_name, psd.avg_supply_cost, rs.s_name, rs.s_acctbal
HAVING SUM(fo.o_totalprice) > 5000
ORDER BY TotalOrderValue DESC NULLS LAST;
