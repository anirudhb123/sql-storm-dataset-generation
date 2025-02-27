WITH NationSummary AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(s.s_acctbal) AS total_acctbal,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
),
PartSupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    ns.nation_name,
    ns.total_acctbal,
    ns.total_customers,
    ns.total_orders,
    pss.total_available_qty,
    pss.avg_supply_cost
FROM 
    NationSummary ns
JOIN 
    PartSupplierSummary pss ON ns.nation_name IN (
        SELECT DISTINCT 
            n.n_name 
        FROM 
            nation n
        JOIN 
            supplier s ON n.n_nationkey = s.s_nationkey
        JOIN 
            partsupp ps ON s.s_suppkey = ps.ps_suppkey
        WHERE 
            ps.ps_availqty > 0
    )
ORDER BY 
    ns.total_acctbal DESC, ns.nation_name;
