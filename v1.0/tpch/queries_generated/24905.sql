WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) 
                           FROM orders o2 
                           WHERE o2.o_orderstatus = o.o_orderstatus)
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS parts_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_supplycost > (SELECT AVG(total_supplycost) FROM SupplierStats)
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_price_normalized
    FROM 
        lineitem lo
    WHERE 
        lo.l_returnflag = 'N' AND
        lo.l_shipmode IN ('AIR', 'SEA')
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    od.total_price_normalized,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    CASE 
        WHEN o.o_totalprice > 10000 THEN 'High Value Order'
        WHEN o.o_totalprice IS NULL THEN 'No Value Order'
        ELSE 'Standard Order'
    END AS order_value_category,
    RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY od.total_price_normalized DESC) AS order_rank
FROM 
    RankedOrders o
LEFT JOIN 
    OrderDetails od ON o.o_orderkey = od.l_orderkey
LEFT JOIN 
    lineitem li ON li.l_orderkey = o.o_orderkey
LEFT JOIN 
    partsupp ps ON ps.ps_partkey = li.l_partkey
LEFT JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
WHERE 
    EXISTS (SELECT 1 
            FROM HighValueSuppliers hvs 
            WHERE hvs.s_suppkey = s.s_suppkey)
ORDER BY 
    o.o_orderdate DESC, 
    order_rank ASC;
