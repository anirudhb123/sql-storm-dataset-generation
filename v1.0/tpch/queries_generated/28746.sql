WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
SupplierLineitems AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_discount,
        l.l_tax,
        l.l_extendedprice,
        l.l_shipdate,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY l.l_shipdate DESC) AS lineitem_rank
    FROM 
        supplier s
    JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
)
SELECT 
    cp.c_name AS "Customer Name",
    COALESCE(rp.p_name, 'No Part') AS "Top Part Name",
    COALESCE(sp.s_name, 'No Supplier') AS "Top Supplier Name",
    co.o_orderkey AS "Last Order Key",
    cp.o_orderdate AS "Last Order Date",
    cp.o_totalprice AS "Total Price",
    sp.l_quantity AS "Last Line Item Quantity",
    sp.l_discount AS "Last Line Item Discount",
    sp.l_tax AS "Last Line Item Tax"
FROM 
    CustomerOrders co
LEFT JOIN 
    RankedParts rp ON co.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = rp.p_partkey
        LIMIT 1
    )
LEFT JOIN 
    SupplierLineitems sp ON sp.l_orderkey = co.o_orderkey
WHERE 
    co.order_rank = 1
    AND rp.price_rank = 1
    AND sp.lineitem_rank = 1
ORDER BY 
    co.o_totalprice DESC;
