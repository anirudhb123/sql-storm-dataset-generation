WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey
),
NationRevenue AS (
    SELECT 
        n.n_nationkey,
        SUM(os.total_revenue) AS nation_revenue
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderSummary os ON o.o_orderkey = os.o_orderkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    r.r_name, 
    COALESCE(n.nation_revenue, 0) AS total_revenue,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    AVG(rs.s_acctbal) AS average_account_balance
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    NationRevenue nr ON n.n_nationkey = nr.n_nationkey
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = (
        SELECT 
            c.c_nationkey 
        FROM 
            customer c 
        WHERE 
            c.c_custkey IN (
                SELECT 
                    o.o_custkey 
                FROM 
                    orders o 
                WHERE 
                    EXISTS (
                        SELECT 
                            1 
                        FROM 
                            lineitem l 
                        WHERE 
                            l.l_orderkey = o.o_orderkey
                    )
            )
        LIMIT 1
    )
GROUP BY 
    r.r_name, n.nation_revenue
ORDER BY 
    total_revenue DESC;
