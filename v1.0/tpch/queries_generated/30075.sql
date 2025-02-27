WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS OrderLevel
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, o.o_orderdate, o.o_totalprice, oh.OrderLevel + 1
    FROM OrderHierarchy oh
    JOIN orders o ON o.o_orderkey > oh.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
SupplierPart AS (
    SELECT s.s_name, p.p_name, ps.ps_supplycost, ps.ps_availqty,
           ROW_NUMBER() OVER(PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS RankByCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
),
AggregateRegion AS (
    SELECT r.r_name, SUM(o.o_totalprice) AS TotalSales,
           COUNT(DISTINCT c.c_custkey) AS UniqueCustomers
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_nationkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY r.r_name
)
SELECT 
    rh.o_orderkey,
    rh.o_orderdate,
    rh.o_totalprice,
    sp.s_name,
    sp.p_name,
    sp.ps_supplycost,
    ar.r_name,
    ar.TotalSales,
    ar.UniqueCustomers,
    CASE 
        WHEN ar.TotalSales > 100000 THEN 'High Sales'
        WHEN ar.TotalSales BETWEEN 50000 AND 100000 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS SalesCategory
FROM 
    OrderHierarchy rh
LEFT JOIN 
    SupplierPart sp ON sp.RankByCost = 1
LEFT JOIN 
    AggregateRegion ar ON ar.TotalSales IS NOT NULL
ORDER BY 
    rh.o_orderdate DESC,
    ar.TotalSales DESC;
