WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s 
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_totalprice, order_year
    HAVING 
        COUNT(l.l_linenumber) > 5
),
NationAggregates AS (
    SELECT 
        n.n_nationkey,
        SUM(s.s_acctbal) AS total_acctbal,
        AVG(s.s_acctbal) AS avg_acctbal,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    r.r_regionkey,
    r.r_name,
    COALESCE(n.total_acctbal, 0) AS cumulative_acctbal,
    (SELECT AVG(ps.ps_supplycost)
     FROM partsupp ps
     WHERE ps.ps_supplycost > (
         SELECT MIN(l.l_discount)
         FROM lineitem l
         WHERE l.l_returnflag = 'N'
         AND l.l_tax IS NOT NULL
     )) AS avg_supplycost,
    COUNT(DISTINCT fo.o_orderkey) AS order_count,
    COUNT(DISTINCT rs.s_suppkey) FILTER (WHERE rs.rank <= 3) AS top_suppliers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    NationAggregates na ON n.n_nationkey = na.n_nationkey
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
LEFT JOIN 
    FilteredOrders fo ON n.n_nationkey = (SELECT n2.n_nationkey FROM nation n2 WHERE n2.n_nationkey = na.n_nationkey)
GROUP BY 
    r.r_regionkey, r.r_name, n.total_acctbal
ORDER BY 
    cumulative_acctbal DESC, order_count ASC;
