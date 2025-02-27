WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ps.ps_availqty,
        ps.ps_supplycost,
        0 AS level
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 10000
    
    UNION ALL

    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ps.ps_availqty,
        ps.ps_supplycost,
        level + 1
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        SupplyChain sc ON sc.s_suppkey = ps.ps_suppkey
    WHERE 
        level < 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
CustomerAnalysis AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN COUNT(DISTINCT o.o_orderkey) > 5 THEN 'Frequent Buyer'
            ELSE 'Occasional Buyer'
        END AS buyer_category
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation,
    r.r_name AS region,
    cs.buyer_category,
    COALESCE(SUM(os.total_revenue), 0) AS total_revenue,
    COALESCE(SUM(sc.ps_supplycost * sc.ps_availqty), 0) AS supply_value,
    AVG(sc.s_acctbal) AS avg_supplier_balance
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerAnalysis cs ON n.n_nationkey = cs.c_custkey
LEFT JOIN 
    OrderSummary os ON cs.c_custkey = os.o_orderkey
LEFT JOIN 
    SupplyChain sc ON n.n_nationkey = sc.s_suppkey
GROUP BY 
    n.n_name, r.r_name, cs.buyer_category
HAVING 
    SUM(os.total_revenue) > 1000 OR COUNT(sc.s_suppkey) > 10
ORDER BY 
    nation, region;
