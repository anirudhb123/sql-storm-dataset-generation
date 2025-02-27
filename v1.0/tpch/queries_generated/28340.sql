WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        c.c_name, 
        o.o_orderdate, 
        o.o_totalprice, 
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
FilteredOrders AS (
    SELECT 
        r.o_orderkey, 
        r.c_name, 
        r.o_orderdate, 
        r.o_totalprice
    FROM RankedOrders r
    WHERE r.OrderRank <= 5
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        s.s_suppkey, 
        s.s_name, 
        p.p_name 
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
AggregatedData AS (
    SELECT 
        fo.o_orderkey, 
        fo.c_name, 
        COUNT(sp.ps_partkey) AS TotalSuppliers, 
        SUM(fo.o_totalprice) AS TotalOrderValue
    FROM FilteredOrders fo
    LEFT JOIN SupplierParts sp ON fo.o_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_orderkey = fo.o_orderkey)
    GROUP BY fo.o_orderkey, fo.c_name
)
SELECT 
    a.o_orderkey, 
    a.c_name, 
    a.TotalSuppliers, 
    a.TotalOrderValue, 
    CASE 
        WHEN a.TotalOrderValue > 10000 THEN 'High Value'
        WHEN a.TotalOrderValue <= 10000 AND a.TotalOrderValue >= 5000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS ValueCategory
FROM AggregatedData a
ORDER BY a.TotalOrderValue DESC;
