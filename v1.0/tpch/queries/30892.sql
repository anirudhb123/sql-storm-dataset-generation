WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_custkey,
        1 AS level
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.o_custkey,
        oh.level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_custkey = oh.o_custkey 
    WHERE 
        o.o_orderdate > oh.o_orderdate
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerMetrics AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SalesRanked AS (
    SELECT 
        cm.c_custkey,
        cm.c_name,
        cm.total_spent,
        ROW_NUMBER() OVER (ORDER BY cm.total_spent DESC) AS sales_rank
    FROM 
        CustomerMetrics cm
)
SELECT 
    p.p_name,
    p.p_size,
    p.p_retailprice,
    ss.s_name AS supplier_name,
    ss.total_avail_qty,
    rh.level AS order_hierarchy_level,
    sr.sales_rank
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    SupplierSummary ss ON ss.s_suppkey = s.s_suppkey
LEFT JOIN 
    OrderHierarchy rh ON rh.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name = ss.s_name LIMIT 1)
LEFT JOIN 
    SalesRanked sr ON sr.c_custkey = (SELECT c.c_custkey FROM customer c WHERE substring(ss.s_name FROM 1 FOR 10) = substring(c.c_name FROM 1 FOR 10) LIMIT 1)
WHERE 
    (p.p_size > 10 AND ss.total_avail_qty IS NOT NULL)
    OR 
    (p.p_retailprice < 100 AND rh.o_orderkey IS NOT NULL)
ORDER BY 
    sr.sales_rank, p.p_name;