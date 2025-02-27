WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
TopSuppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.nation_name
    FROM 
        RankedSuppliers r
    WHERE 
        r.rank <= 3
),
PartOrderSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    JOIN 
        orders o ON li.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND 
        o.o_orderdate < '2024-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_supplycost, 
        p.p_name 
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    psd.p_name,
    COALESCE(SUM(psd.ps_supplycost), 0) AS total_supply_cost,
    COALESCE(ps.tot_revenue, 0) AS total_revenue,
    COUNT(DISTINCT ts.s_suppkey) AS supplier_count
FROM 
    PartSupplierDetails psd
LEFT JOIN 
    TopSuppliers ts ON psd.ps_suppkey = ts.s_suppkey
LEFT JOIN 
    (SELECT 
        p.p_partkey, 
        SUM(total_revenue) AS tot_revenue
    FROM 
        PartOrderSummary
    GROUP BY 
        p.p_partkey) p ON psd.ps_partkey = p.p_partkey
GROUP BY 
    psd.p_name, psd.ps_partkey
ORDER BY 
    total_supply_cost DESC, total_revenue DESC;
