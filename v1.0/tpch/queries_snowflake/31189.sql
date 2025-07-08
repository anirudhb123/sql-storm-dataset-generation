
WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        p.p_partkey,
        p.p_retailprice,
        1 AS level
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        p.p_partkey,
        p.p_retailprice,
        level + 1
    FROM 
        SupplyChain sc
    JOIN 
        partsupp ps ON sc.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0 AND level < 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS total_items,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        COALESCE(SUM(s.s_acctbal), 0) AS total_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    COALESCE(ns.supplier_count, 0) AS supplier_count,
    COALESCE(ns.total_balance, 0.00) AS total_balance,
    SUM(ss.ps_availqty) AS total_available_quantity,
    SUM(ss.p_retailprice * ss.ps_availqty) AS potential_revenue,
    COUNT(DISTINCT os.o_orderkey) AS total_orders
FROM 
    region r
LEFT JOIN 
    NationStats ns ON r.r_regionkey = ns.n_nationkey
LEFT JOIN 
    SupplyChain ss ON ss.s_suppkey IS NOT NULL
LEFT JOIN 
    OrderSummary os ON ss.p_partkey = os.o_orderkey
GROUP BY 
    r.r_name, ns.supplier_count, ns.total_balance
HAVING 
    SUM(ss.ps_availqty) > 0 OR COUNT(DISTINCT os.o_orderkey) > 0
ORDER BY 
    total_available_quantity DESC, potential_revenue DESC;
