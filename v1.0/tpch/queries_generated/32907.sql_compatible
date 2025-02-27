
WITH RECURSIVE OrderCTE AS (
    SELECT o_orderkey, o_orderdate, o_totalprice, o_custkey, 1 AS OrderLevel
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, oc.OrderLevel + 1
    FROM orders o
    JOIN OrderCTE oc ON o.o_custkey = oc.o_custkey AND o.o_orderdate > oc.o_orderdate
)
SELECT 
    c.c_custkey, 
    c.c_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS TotalSales,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    SUM(CASE 
            WHEN li.l_returnflag = 'R' THEN 1
            ELSE 0 
        END) AS ReturnedItems,
    AVG(COALESCE(li.l_tax, 0)) AS AvgTax,
    ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(li.l_extendedprice) DESC) AS NationRank
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN 
    partsupp ps ON li.l_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    c.c_acctbal > (
        SELECT AVG(c2.c_acctbal)
        FROM customer c2
        WHERE c2.c_nationkey = c.c_nationkey
    )
    AND n.n_regionkey IN (1, 2, 3) 
    AND li.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    c.c_custkey, c.c_name, c.c_nationkey
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 1000
ORDER BY 
    TotalSales DESC
LIMIT 10;
