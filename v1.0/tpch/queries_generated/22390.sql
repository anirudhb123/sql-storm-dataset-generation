WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, GETDATE())
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
        COUNT(l.l_linenumber) AS line_count,
        SUM(l.l_quantity) AS total_quantity,
        MAX(l.l_tax) AS max_tax_rate
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    DISTINCT 
    o.o_orderkey,
    COALESCE(o.o_totalprice, 0) AS order_total,
    COALESCE(oli.total_price_after_discount, 0) AS discounted_price,
    s.s_name,
    RANK() OVER (PARTITION BY o.o_orderkey ORDER BY s.total_parts DESC) AS supplier_rank
FROM 
    RankedOrders o
LEFT JOIN 
    OrderLineItems oli ON o.o_orderkey = oli.l_orderkey
LEFT JOIN 
    SupplierDetails s ON EXISTS (
        SELECT 1 FROM partsupp ps
        WHERE ps.ps_partkey IN (SELECT ps_partkey FROM lineitem WHERE l_orderkey = o.o_orderkey)
        AND ps.ps_suppkey = s.s_suppkey
    )
WHERE 
    o.o_orderstatus IN ('O', 'F')
    AND (oli.total_quantity IS NULL OR oli.total_quantity > 0)
ORDER BY 
    o.o_orderdate DESC,
    supplier_rank;
