WITH SupplierPartPrices AS (
    SELECT 
        s.s_suppkey,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        n.n_name
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, n.n_name
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(odp.total_revenue) AS total_revenue
    FROM 
        OrderDetails odp
    JOIN 
        nation n ON odp.n_name = n.n_name
    GROUP BY 
        n.n_name
    ORDER BY 
        total_revenue DESC
    LIMIT 5
)
SELECT 
    sp.p_name,
    sp.ps_supplycost,
    tn.total_revenue
FROM 
    SupplierPartPrices sp
JOIN 
    TopNations tn ON tn.n_name = (
        SELECT 
            n.n_name 
        FROM 
            nation n 
        JOIN 
            supplier s ON n.n_nationkey = s.s_nationkey 
        WHERE 
            s.s_suppkey = sp.s_suppkey 
        LIMIT 1
    )
ORDER BY 
    tn.total_revenue DESC, sp.ps_supplycost ASC;