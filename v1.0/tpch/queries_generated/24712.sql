WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.* 
    FROM 
        RankedSuppliers r
    WHERE 
        r.rnk <= 3
),
PartPrices AS (
    SELECT 
        p.p_partkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        lineitem l ON ps.ps_suppkey = l.l_suppkey
    WHERE 
        l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        p.p_partkey
),
UnusualCombinations AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey,
        CASE 
            WHEN p.p_size % 2 = 0 THEN 'Even'
            ELSE 'Odd'
        END AS size_category,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 0
        AND MAX(l.l_returnflag) IS NULL
)
SELECT 
    ns.n_name,
    pp.p_partkey,
    pp.avg_supply_cost,
    pp.total_revenue,
    uc.size_category,
    uc.order_count
FROM 
    nation ns
LEFT JOIN 
    TopSuppliers ts ON ts.s_nationkey = ns.n_nationkey
LEFT JOIN 
    PartPrices pp ON pp.p_partkey = ts.s_suppkey
RIGHT JOIN 
    UnusualCombinations uc ON pp.p_partkey = uc.ps_partkey
WHERE 
    (pp.avg_supply_cost IS NULL OR pp.total_revenue > 1000)
    AND ns.r_name NOT LIKE '%Region%'
ORDER BY 
    ns.n_name, pp.total_revenue DESC NULLS LAST;
