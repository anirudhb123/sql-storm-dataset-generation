
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_price,
        COUNT(l.l_linenumber) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name
    FROM 
        SupplierDetails s
    WHERE 
        s.total_supplycost > (SELECT AVG(total_supplycost) FROM SupplierDetails)
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    ol.total_lineitem_price,
    ol.item_count,
    COALESCE(ts.s_name, 'No Top Supplier') AS top_supplier_name
FROM 
    RankedOrders o
LEFT JOIN 
    OrderLineItems ol ON o.o_orderkey = ol.l_orderkey
LEFT JOIN 
    TopSuppliers ts ON ol.l_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
WHERE 
    o.order_rank <= 10
ORDER BY 
    o.o_totalprice DESC, o.o_orderdate;
