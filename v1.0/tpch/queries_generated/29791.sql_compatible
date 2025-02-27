
WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with availability: ', ps.ps_availqty, ' at cost: $', ROUND(ps.ps_supplycost, 2)) AS SupplierPartInfo
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        CONCAT(c.c_name, ' placed order #', o.o_orderkey, ' with total price: $', ROUND(o.o_totalprice, 2)) AS CustomerOrderInfo
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
OrderLineItemDetails AS (
    SELECT 
        ol.l_orderkey,
        COUNT(ol.l_linenumber) AS LineItemCount,
        SUM(ol.l_extendedprice) AS TotalExtendedPrice,
        STRING_AGG(ol.l_comment, '; ') AS LineComments
    FROM 
        lineitem ol
    GROUP BY 
        ol.l_orderkey
)
SELECT 
    spd.SupplierPartInfo,
    cod.CustomerOrderInfo,
    ol.LineItemCount,
    ol.TotalExtendedPrice,
    ol.LineComments
FROM 
    SupplierPartDetails spd
JOIN 
    CustomerOrderDetails cod ON spd.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%widget%'))
JOIN 
    OrderLineItemDetails ol ON ol.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cod.c_custkey)
WHERE 
    spd.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp);
