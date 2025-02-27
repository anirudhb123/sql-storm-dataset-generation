
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_status
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS supplier_value,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.supplier_value > (SELECT AVG(ss1.supplier_value) FROM SupplierStats ss1)
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank,
    COALESCE(l.net_sales, 0) AS net_sales,
    hs.s_name AS high_value_suppliers
FROM 
    RankedOrders o
LEFT JOIN 
    LineItemAnalysis l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    HighValueSuppliers hs ON o.o_orderkey = (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_orderkey = o.o_orderkey 
        ORDER BY l.l_extendedprice DESC 
        LIMIT 1
    )
WHERE 
    o.o_orderstatus IN ('O', 'F') 
AND 
    (o.o_totalprice > (SELECT AVG(o_sub.o_totalprice) FROM orders o_sub) OR o.o_orderdate IS NULL)
ORDER BY 
    o.o_orderdate DESC, order_rank;
