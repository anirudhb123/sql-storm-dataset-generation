WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
TopNations AS (
    SELECT 
        ns.n_nationkey,
        ns.n_name,
        ns.supplier_count,
        ns.total_acctbal,
        rs.s_name AS top_supplier_name
    FROM 
        NationSummary ns
    LEFT JOIN 
        RankedSuppliers rs ON ns.n_nationkey = rs.s_nationkey AND rs.rank = 1
    WHERE 
        ns.total_acctbal IS NOT NULL
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_price,
        COUNT(l.l_linenumber) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    tn.n_name,
    tn.supplier_count,
    tn.total_acctbal,
    COALESCE(os.total_lineitem_price, 0) AS total_order_income,
    CASE 
        WHEN tn.total_acctbal > 100000 THEN 'High Value'
        WHEN tn.total_acctbal IS NULL THEN 'Unknown Value'
        ELSE 'Normal Value'
    END AS account_value_category,
    STRING_AGG(DISTINCT rs.p_name, ', ') AS part_names
FROM 
    TopNations tn
LEFT JOIN 
    orders o ON tn.n_nationkey = o.o_orderkey -- Using the order key incorrectly to create an outer join scenario
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    part rs ON ps.ps_partkey = rs.p_partkey
GROUP BY 
    tn.n_name, tn.supplier_count, tn.total_acctbal
HAVING 
    SUM(l.l_quantity) IS NULL OR COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY 
    tn.total_acctbal DESC NULLS LAST;
