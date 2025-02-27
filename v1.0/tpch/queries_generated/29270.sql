WITH SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        CONCAT('Supplier: ', s.s_name, ', Address: ', s.s_address, ', Phone: ', s.s_phone) AS SupplierDetails,
        SUM(ps.ps_availqty) AS TotalAvailableQuantity,
        STRING_AGG(CONCAT('Part: ', p.p_name, ', Price: ', p.p_retailprice), '; ') AS PartsDetails
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        STRING_AGG(CONCAT('Item: ', l.l_linenumber, ', Quantity: ', l.l_quantity), '; ') AS LineItems
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    spi.SupplierDetails,
    spi.TotalAvailableQuantity,
    os.o_orderkey,
    os.o_orderdate,
    os.TotalRevenue,
    os.LineItems
FROM 
    SupplierPartInfo spi
JOIN 
    OrderSummary os ON spi.TotalAvailableQuantity > 100 -- example condition for filtering
ORDER BY 
    os.TotalRevenue DESC;
