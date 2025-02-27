WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE 
        sh.level < 5
), 
PartAggregation AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), 
OrderInfo AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS line_item_count,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
), 
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    p.p_name,
    pa.total_supply_cost,
    o.total_sales,
    ns.total_suppliers,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY o.total_sales DESC) AS sales_rank,
    sh.level AS supplier_hierarchy_level
FROM 
    PartAggregation pa
JOIN 
    OrderInfo o ON pa.p_partkey = (SELECT DISTINCT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey LIMIT 1)
JOIN 
    NationSummary ns ON ns.total_suppliers > 0
LEFT JOIN 
    SupplierHierarchy sh ON sh.s_nationkey = ns.n_nationkey
WHERE 
    (pa.total_supply_cost > 1000 OR ns.total_acctbal IS NULL)
ORDER BY 
    pa.total_supply_cost DESC, o.total_sales DESC;
