WITH NationSupplier AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        COUNT(ps.ps_suppkey) AS partsupplier_count,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
Revenue AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2022-12-31'
    GROUP BY 
        o.o_orderkey
),
FinalReport AS (
    SELECT 
        ns.nation_name,
        ns.supplier_count,
        ns.total_acctbal,
        ps.partsupplier_count,
        ps.avg_supplycost,
        rv.total_revenue
    FROM 
        NationSupplier ns
    LEFT JOIN 
        PartSupplier ps ON ns.nation_name = (SELECT n_name FROM nation WHERE n_nationkey = (SELECT DISTINCT s_nationkey FROM supplier WHERE s_suppkey = ps.ps_suppkey))
    LEFT JOIN 
        Revenue rv ON rv.o_orderkey IS NOT NULL
    WHERE 
        rv.total_revenue IS NOT NULL
)
SELECT 
    nation_name,
    supplier_count,
    total_acctbal,
    partsupplier_count,
    avg_supplycost,
    COALESCE(SUM(total_revenue), 0) AS total_revenue
FROM 
    FinalReport
GROUP BY 
    nation_name, supplier_count, total_acctbal, partsupplier_count, avg_supplycost
ORDER BY 
    total_acctbal DESC, total_revenue DESC;
