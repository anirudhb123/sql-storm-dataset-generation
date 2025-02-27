WITH SupplierParts AS (
    SELECT 
        s.s_name AS SupplierName,
        p.p_name AS PartName,
        p.p_brand AS Brand,
        ps.ps_availqty AS AvailableQuantity,
        ps.ps_supplycost AS SupplyCost,
        ps.ps_comment AS PartComment
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), 
CustomerOrders AS (
    SELECT 
        c.c_name AS CustomerName,
        o.o_orderkey AS OrderKey,
        o.o_totalprice AS TotalPrice,
        o.o_orderdate AS OrderDate,
        o.o_comment AS OrderComment
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
LineItemDetails AS (
    SELECT 
        lo.l_orderkey AS OrderKey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS TotalSales,
        COUNT(lo.l_linenumber) AS LineItemCount
    FROM lineitem lo
    GROUP BY lo.l_orderkey
)
SELECT 
    sp.SupplierName,
    sp.PartName,
    sp.Brand,
    sp.PartComment,
    co.CustomerName,
    co.TotalPrice,
    co.OrderDate,
    li.TotalSales,
    li.LineItemCount
FROM SupplierParts sp
JOIN CustomerOrders co ON sp.SupplierName LIKE '%' || SUBSTR(co.CustomerName, 1, 3) || '%'
JOIN LineItemDetails li ON co.OrderKey = li.OrderKey
WHERE sp.AvailableQuantity > 100
ORDER BY li.TotalSales DESC, co.OrderDate ASC;
