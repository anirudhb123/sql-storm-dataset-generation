WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        CONCAT(s.s_name, ' located at ', s.s_address) AS SupplierInfo,
        SUBSTRING(s.s_comment, 1, 20) AS ShortComment
    FROM 
        supplier s
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_container,
        p.p_retailprice,
        CONCAT(p.p_name, ' is a ', p.p_container) AS PartContainerInfo
    FROM 
        part p
),
LineItemInfo AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_shipmode,
        CONCAT(l.l_shipmode, ' - Order Key: ', l.l_orderkey) AS ShippingDetails
    FROM 
        lineitem l
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT li.l_linenumber) AS TotalLineItems,
        STRING_AGG(DISTINCT CONCAT(li.l_shipmode, ' for Part ', pd.p_name), ', ') AS ShippingModes
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    JOIN 
        PartDetails pd ON li.l_partkey = pd.p_partkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    od.o_orderkey,
    od.o_orderstatus,
    od.TotalRevenue,
    od.TotalLineItems,
    sd.SupplierInfo,
    pd.PartContainerInfo,
    od.ShippingModes
FROM 
    OrderSummary od
JOIN 
    LineItemInfo li ON od.o_orderkey = li.l_orderkey
JOIN 
    SupplierDetails sd ON li.l_suppkey = sd.s_suppkey
JOIN 
    PartDetails pd ON li.l_partkey = pd.p_partkey
WHERE 
    od.TotalRevenue > 1000
ORDER BY 
    od.TotalRevenue DESC;
