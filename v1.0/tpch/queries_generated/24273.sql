WITH RegionalSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        DENSE_RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS RankInRegion
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),

OrderLineItemDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_discount) AS TotalDiscount,
        COUNT(DISTINCT l.l_linenumber) AS LineItemCount,
        (SELECT COUNT(*) FROM lineitem l2 WHERE l2.l_orderkey = o.o_orderkey) AS AllLineItemCount,
        MAX(l.l_extendedprice) AS HighestExtendedPrice
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)

SELECT 
    r.r_name,
    COALESCE(SUM(ol.LineItemCount), 0) AS TotalLineItems,
    COUNT(DISTINCT rs.s_suppkey) AS SupplierCount,
    CASE 
        WHEN COUNT(DISTINCT rs.s_suppkey) > 5 THEN 'Many'
        WHEN COUNT(DISTINCT rs.s_suppkey) BETWEEN 3 AND 5 THEN 'Some'
        ELSE 'Few'
    END AS SupplierDescription,
    AVG(ol.TotalDiscount) AS AverageDiscount,
    AVG(rs.TotalSupplyCost) AS AverageSupplyCost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RegionalSuppliers rs ON n.n_nationkey = rs.s_nationkey AND rs.RankInRegion = 1
LEFT JOIN 
    OrderLineItemDetails ol ON ol.o_orderkey IN (
        SELECT DISTINCT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'F' 
        AND EXISTS (
            SELECT 1 
            FROM lineitem l 
            WHERE l.l_orderkey = o.o_orderkey 
            AND l.l_returnflag = 'R'
        )
    )
GROUP BY 
    r.r_name
HAVING 
    SUM(ol.LineItemCount) IS NOT NULL
    AND COUNT(DISTINCT rs.s_suppkey) NOT BETWEEN 2 AND 4
ORDER BY 
    r.r_name;
