WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_shippriority,
        1 AS order_level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= DATE '2023-01-01' 
    UNION ALL
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_shippriority,
        oh.order_level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_orderkey < oh.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
),
AvgCostPerPart AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
SupplierSummary AS (
    SELECT 
        s.s_nationkey,
        SUM(s.s_acctbal) AS total_acctbal,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    GROUP BY 
        s.s_nationkey
),
Result AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        COALESCE(avg_cost.avg_supply_cost, 0) AS avg_supply_cost,
        ss.total_acctbal,
        ss.supplier_count,
        COUNT(oh.o_orderkey) AS order_count
    FROM 
        part p
    LEFT OUTER JOIN 
        AvgCostPerPart avg_cost ON p.p_partkey = avg_cost.ps_partkey
    LEFT JOIN 
        SupplierSummary ss ON ss.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    LEFT JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    LEFT JOIN 
        orders oh ON li.l_orderkey = oh.o_orderkey
    GROUP BY 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        avg_cost.avg_supply_cost, 
        ss.total_acctbal, 
        ss.supplier_count
)
SELECT 
    r.*,
    RANK() OVER (PARTITION BY r.p_brand ORDER BY r.order_count DESC) AS brand_order_rank
FROM 
    Result r
WHERE 
    r.order_count > 0
ORDER BY 
    r.order_count DESC, 
    r.total_acctbal DESC;
