WITH RecursiveCustomerCTE AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_mktsegment
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal * 0.9, c.c_mktsegment
    FROM customer c
    JOIN RecursiveCustomerCTE r ON c.c_custkey = r.c_custkey
    WHERE c.c_acctbal < r.c_acctbal
), 
SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue,
           COUNT(DISTINCT ps.ps_partkey) AS PartCount
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.TotalSupplyValue,
           ROW_NUMBER() OVER (ORDER BY s.TotalSupplyValue DESC) AS Rank
    FROM SupplierSummary s
    WHERE s.PartCount > (
        SELECT AVG(PartCount) FROM SupplierSummary
    )
)
SELECT 
    r.c_name AS CustomerName,
    r.c_acctbal AS AccountBalance,
    COALESCE(t.TotalSupplyValue, 0) AS SupplierValue,
    p.p_mfgr AS Manufacturer,
    p.p_brand AS Brand,
    COUNT(DISTINCT l.l_orderkey) AS OrderCount,
    SUM(l.l_discount) OVER (PARTITION BY l.l_suppkey ORDER BY l.l_orderkey ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS TotalDiscount,
    CASE 
        WHEN r.c_mktsegment = 'BUILDING' THEN 'HIGHEST PRIORITY'
        WHEN r.c_acctbal > 10000 THEN 'HIGH PRIORITY'
        ELSE 'NORMAL PRIORITY'
    END AS CustomerPriority,
    STRING_AGG(DISTINCT s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS SupplierNames
FROM RecursiveCustomerCTE r
LEFT JOIN orders o ON r.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN TopSuppliers t ON ps.ps_suppkey = t.s_suppkey
LEFT JOIN part p ON l.l_partkey = p.p_partkey
GROUP BY r.c_name, r.c_acctbal, t.TotalSupplyValue, p.p_mfgr, p.p_brand
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY r.c_acctbal DESC, SupplierValue DESC;

