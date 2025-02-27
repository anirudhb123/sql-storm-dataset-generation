WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 as Level
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.Level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_custkey = oh.o_orderkey) 
    WHERE o.o_orderstatus = 'O'
),
PartSupplierStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerStats AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_custkey) AS CustomerCount,
        SUM(o.o_totalprice) AS TotalRevenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY c.c_nationkey
),
RegionStats AS (
    SELECT 
        r.r_regionkey,
        COUNT(DISTINCT n.n_nationkey) AS NationCount,
        SUM(cs.CustomerCount) AS TotalCustomers
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN CustomerStats cs ON n.n_nationkey = cs.c_nationkey
    GROUP BY r.r_regionkey
)

SELECT 
    rh.o_orderkey,
    rh.o_orderdate,
    rh.o_totalprice,
    ps.TotalSupplyCost,
    ps.SupplierCount,
    rs.NationCount,
    rs.TotalCustomers,
    COUNT(DISTINCT c.c_custkey) OVER (PARTITION BY rh.o_orderkey) AS DistinctCustomers
FROM OrderHierarchy rh
JOIN PartSupplierStats ps ON ps.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = rh.o_orderkey LIMIT 1)
JOIN RegionStats rs ON rs.NationCount > 0
LEFT JOIN customer c ON c.c_custkey = rh.o_orderkey
WHERE ps.TotalSupplyCost IS NOT NULL
AND (rh.o_orderdate BETWEEN DATEADD(DAY, -30, CURRENT_DATE) AND CURRENT_DATE)
ORDER BY rh.o_orderdate DESC, rh.o_orderkey;
