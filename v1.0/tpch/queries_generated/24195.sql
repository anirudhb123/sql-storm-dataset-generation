WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as acct_rank,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown Account Balance'
            WHEN s.s_acctbal < 5000 THEN 'Low Balance'
            WHEN s.s_acctbal BETWEEN 5000 AND 15000 THEN 'Medium Balance'
            ELSE 'High Balance'
        END AS balance_category
    FROM 
        supplier s
), 
NationWithMaxSuppliers AS (
    SELECT 
        n.n_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        MAX(s.s_acctbal) AS max_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
    HAVING 
        COUNT(DISTINCT s.s_suppkey) >= 1
), 
HighBalanceSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.balance_category,
        n.n_name,
        n.r_regionkey
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.acct_rank = 1 AND rs.balance_category = 'High Balance'
), 
OrderTotals AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        o.o_shippriority
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate = (SELECT MAX(l2.l_shipdate) FROM lineitem l2 WHERE l2.l_orderkey = o.o_orderkey)
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_shippriority
)

SELECT 
    n.n_name,
    rs.s_name,
    ot.o_orderkey,
    ot.total_revenue,
    ot.o_shippriority,
    CASE 
        WHEN ot.total_revenue IS NULL THEN 'No Revenue'
        WHEN ot.total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_status
FROM 
    HighBalanceSuppliers rs
JOIN 
    NationWithMaxSuppliers nwm ON rs.n_nationkey = nwm.n_nationkey
FULL OUTER JOIN 
    OrderTotals ot ON rs.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                               FROM part p 
                               WHERE (p.p_size IS NULL OR p.p_size > 10) AND p.p_retailprice > 50.00)
        LIMIT 1
    )
WHERE 
    nwm.max_acctbal IS NOT NULL
ORDER BY 
    n.n_name, ot.total_revenue DESC;
