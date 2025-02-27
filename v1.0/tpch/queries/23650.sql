WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
TotalSpending AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        l.l_suppkey
),
ActiveSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        COUNT(DISTINCT p.p_partkey) > 5
)
SELECT 
    r.n_name AS nation,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice) AS avg_price,
    COALESCE(SUM(ts.total_spent), 0) AS total_spending,
    COALESCE(MAX(ads.total_available), 0) AS max_available_parts,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    nation r
LEFT JOIN 
    customer c ON c.c_nationkey = r.n_nationkey
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey
LEFT JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    RankedSuppliers s ON s.s_suppkey = l.l_suppkey AND s.rnk = 1
LEFT JOIN 
    TotalSpending ts ON ts.l_suppkey = l.l_suppkey
LEFT JOIN 
    ActiveSuppliers ads ON ads.ps_suppkey = l.l_suppkey
WHERE 
    (l.l_returnflag = 'R' AND l.l_linestatus = 'O') OR (l.l_returnflag <> 'R' AND l.l_linestatus <> 'O')
GROUP BY 
    r.n_name
ORDER BY 
    total_orders DESC NULLS LAST,
    avg_price ASC NULLS FIRST;