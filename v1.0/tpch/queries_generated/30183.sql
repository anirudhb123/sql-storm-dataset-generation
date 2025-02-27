WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        0 AS level
    FROM 
        supplier s
    WHERE 
        s.s_suppkey IS NOT NULL
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        COUNT(DISTINCT li.l_suppkey) AS supplier_count
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
RegionAnalysis AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        MAX(s.s_acctbal) AS max_supplier_balance
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    p.p_mfgr,
    p.p_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY SUM(ps.ps_availqty) DESC) AS rank,
    ra.region_name,
    ra.nation_count,
    COALESCE(oh.total_sales, 0) AS order_total_sales,
    CASE 
        WHEN oh.supplier_count > 0 THEN 'Supplied'
        ELSE 'Not Supplied' 
    END AS supply_status
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    (SELECT DISTINCT ON (o.o_orderkey)
        o.o_orderkey, 
        os.total_sales, 
        os.supplier_count 
     FROM 
        OrderSummary os
     JOIN 
        orders o ON os.o_orderkey = o.o_orderkey) oh ON p.p_partkey = oh.o_orderkey
JOIN 
    RegionAnalysis ra ON p.p_mfgr = ra.r_name
GROUP BY 
    p.p_partkey, p.p_mfgr, p.p_name, ra.region_name, oh.total_sales, oh.supplier_count
HAVING 
    SUM(ps.ps_availqty) > 10 AND 
    AVG(ps.ps_supplycost) IS NOT NULL
ORDER BY 
    total_available_quantity DESC, 
    rank;
