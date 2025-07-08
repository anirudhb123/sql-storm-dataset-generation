
WITH SupplierOrderSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ss.total_revenue,
        ss.total_orders,
        ss.revenue_rank
    FROM 
        supplier s
    JOIN 
        SupplierOrderSummary ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.revenue_rank <= 10
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT ts.s_suppkey) AS supplier_count,
    AVG(ts.s_acctbal) AS avg_account_balance,
    SUM(ts.total_revenue) AS total_revenues
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT OUTER JOIN 
    TopSuppliers ts ON n.n_nationkey = (
        SELECT 
            s_nationkey 
        FROM 
            supplier 
        WHERE 
            s_suppkey = ts.s_suppkey
    )
GROUP BY 
    r.r_name, n.n_name
HAVING 
    SUM(ts.total_revenue) IS NOT NULL
ORDER BY 
    total_revenues DESC;
