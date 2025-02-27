WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS total_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
NationRevenue AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(os.total_revenue) AS total_revenue
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderSummary os ON o.o_orderkey = os.o_orderkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    s.s_name,
    ns.total_supplycost,
    nr.total_revenue
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers s ON n.n_nationkey = s.s_nationkey AND s.rank = 1
LEFT JOIN 
    NationRevenue nr ON n.n_nationkey = nr.n_nationkey
LEFT JOIN 
    (
        SELECT 
            n.n_nationkey,
            SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
        FROM 
            partsupp ps
        JOIN 
            supplier s ON ps.ps_suppkey = s.s_suppkey
        JOIN 
            nation n ON s.s_nationkey = n.n_nationkey
        GROUP BY 
            n.n_nationkey
    ) ns ON n.n_nationkey = ns.n_nationkey
WHERE 
    (nr.total_revenue IS NULL OR ns.total_supplycost > nr.total_revenue)
ORDER BY 
    r.r_name, nation_name, ns.total_supplycost DESC;
