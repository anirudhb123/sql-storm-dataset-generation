WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
NationalStats AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(p.p_retailprice) AS avg_retailprice
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    ns.customer_count,
    ns.total_supplier_balance,
    pd.p_name,
    pd.total_available,
    pd.avg_retailprice,
    ro.total_revenue
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    NationalStats ns ON n.n_name = ns.n_name
LEFT JOIN 
    PartDetails pd ON pd.p_partkey IN (
        SELECT 
            l.l_partkey 
        FROM 
            lineitem l 
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey 
        WHERE 
            o.o_orderdate BETWEEN DATE '2023-06-01' AND DATE '2023-12-31'
    )
LEFT JOIN 
    RankedOrders ro ON ro.o_custkey IN (
        SELECT 
            c.c_custkey 
        FROM 
            customer c 
        JOIN 
            orders o ON c.c_custkey = o.o_custkey 
        WHERE 
            o.o_orderdate = (
                SELECT MAX(o2.o_orderdate) 
                FROM orders o2 
                WHERE o2.o_custkey = c.c_custkey
            )
    )
WHERE 
    ns.customer_count IS NOT NULL OR pd.total_available IS NOT NULL
ORDER BY 
    r.r_name, ns.total_supplier_balance DESC;
