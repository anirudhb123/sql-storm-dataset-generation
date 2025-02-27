WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate <= '1997-12-31'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM lineitem l
    GROUP BY l.l_orderkey
),
AverageSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales
    FROM OrderLineItems
)
SELECT 
    p.p_name,
    p.p_size,
    COALESCE(sc.total_cost, 0) AS supplier_total_cost,
    o.total_sales,
    o.distinct_parts,
    CASE 
        WHEN o.total_sales > (SELECT avg_sales FROM AverageSales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_comparison
FROM part p 
LEFT JOIN SupplierCost sc ON p.p_partkey = sc.ps_partkey
JOIN OrderLineItems o ON o.l_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_partkey = p.p_partkey
)
LEFT JOIN RankedOrders ro ON ro.o_orderkey = o.l_orderkey
WHERE ro.rn = 1
ORDER BY supplier_total_cost DESC, o.total_sales DESC
LIMIT 50;