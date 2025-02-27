WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank_acctbal,
        COUNT(*) OVER (PARTITION BY p.p_partkey) AS total_suppliers
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_nationkey IN (
                SELECT n.n_nationkey 
                FROM nation n 
                WHERE n.n_regionkey IS NOT NULL
            )
        )
), FilteredLineItems AS (
    SELECT 
        l.*,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS line_num
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2022-01-01' 
        AND l.l_shipdate < '2023-01-01'
        AND l.l_discount <> 0
)

SELECT 
    p.p_name,
    COUNT(DISTINCT ls.l_orderkey) AS total_orders,
    SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance, 
    MAX(CASE WHEN rs.rank_acctbal = 1 THEN rs.s_name END) AS top_supplier,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ': ', rs.s_name), '; ') AS all_top_suppliers,
    SUM(CASE WHEN ls.l_returnflag = 'R' THEN 1 ELSE 0 END) AS total_returns,
    NULLIF(SUM(ls.l_quantity * CASE WHEN ls.l_linestatus = 'O' THEN 1 ELSE 0 END), 0) AS total_ordered_quantity,
    COALESCE(NULLIF(MAX(rs.total_suppliers), 0), 'No Suppliers') AS supplier_count
FROM 
    FilteredLineItems ls
LEFT JOIN 
    RankedSuppliers rs ON ls.l_suppkey = rs.s_suppkey
JOIN 
    part p ON ls.l_partkey = p.p_partkey
JOIN 
    customer c ON c.c_custkey = ls.l_orderkey 
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
GROUP BY 
    p.p_name
HAVING 
    SUM(ls.l_extendedprice) > (SELECT AVG(l_extendedprice) FROM lineitem)
ORDER BY 
    total_revenue DESC;
