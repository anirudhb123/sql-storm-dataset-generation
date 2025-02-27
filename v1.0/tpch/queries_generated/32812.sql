WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        o.o_shippriority,
        1 AS level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'  -- Only considering open orders for hierarchy
    
    UNION ALL
    
    SELECT 
        oh.o_orderkey,
        oh.o_orderstatus,
        oh.o_orderdate,
        oh.o_totalprice,
        oh.o_shippriority,
        oh.level + 1
    FROM 
        OrderHierarchy oh
    JOIN 
        orders o ON o.o_orderkey = oh.o_orderkey
    WHERE 
        o.o_orderdate <= CURRENT_DATE - INTERVAL (oh.level || ' days')::interval
),
SupplierPart AS (
    SELECT 
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_partkey
),
RankedSuppliers AS (
    SELECT 
        sp.s_name,
        sp.p_name,
        ROW_NUMBER() OVER (PARTITION BY sp.p_name ORDER BY sp.ps_supplycost) AS supplier_rank
    FROM 
        SupplierPart sp
),
FilteredOrders AS (
    SELECT 
        oh.o_orderkey,
        oh.o_orderdate,
        COUNT(DISTINCT li.l_orderkey) AS lineitem_count
    FROM 
        OrderHierarchy oh
    LEFT JOIN 
        lineitem li ON oh.o_orderkey = li.l_orderkey
    GROUP BY 
        oh.o_orderkey, oh.o_orderdate
)
SELECT 
    r.supplier_name,
    r.part_name,
    ts.total_revenue,
    fo.lineitem_count
FROM 
    RankedSuppliers r
JOIN 
    TotalSales ts ON r.p_name = ts.l_partkey
LEFT JOIN 
    FilteredOrders fo ON fo.o_orderkey = r.supplier_rank and fo.lineitem_count IS NOT NULL
WHERE 
    r.supplier_rank <= 5
ORDER BY 
    ts.total_revenue DESC, fo.lineitem_count
LIMIT 10;
