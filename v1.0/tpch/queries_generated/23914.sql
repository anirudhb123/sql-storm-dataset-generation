WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank_by_balance
    FROM 
        supplier s
), FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CASE 
            WHEN p.p_size IS NULL THEN 'UNKNOWN' 
            WHEN p.p_size BETWEEN 1 AND 10 THEN 'SMALL'
            WHEN p.p_size BETWEEN 11 AND 20 THEN 'MEDIUM'
            WHEN p.p_size > 20 THEN 'LARGE'
        END AS size_category,
        COUNT(ps.ps_partkey) AS supplier_count
    FROM 
        part p
        LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_size
), OrdersWithTotal AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        CASE WHEN o.o_orderstatus IS NULL THEN 'NO STATUS' ELSE o.o_orderstatus END AS order_status
    FROM 
        orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderstatus
)

SELECT 
    r.r_name AS region_name,
    np.n_name AS nation_name,
    fs.p_name AS part_name,
    fs.size_category,
    COUNT(DISTINCT rs.s_suppkey) AS distinct_suppliers,
    SUM(ot.total_order_value) AS total_order_value
FROM 
    region r
    JOIN nation np ON np.n_regionkey = r.r_regionkey
    LEFT JOIN RankedSuppliers rs ON rs.rank_by_balance < 5 AND rs.s_nationkey = np.n_nationkey
    JOIN FilteredParts fs ON fs.supplier_count > 0
    LEFT JOIN OrdersWithTotal ot ON ot.o_custkey = np.n_nationkey
WHERE 
    fs.size_category IS NOT NULL OR fs.size_category != 'UNKNOWN'
    AND (ot.total_order_value > 1000 OR ot.total_order_value IS NULL) 
GROUP BY 
    r.r_name, np.n_name, fs.p_name, fs.size_category
HAVING 
    AVG(rs.s_acctbal) IS NOT NULL
ORDER BY 
    r.r_name, np.n_name, SUM(ot.total_order_value) DESC;
