WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        LAG(s.s_acctbal) OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS previous_balance,
        s.s_acctbal AS current_balance,
        (s.s_acctbal - LAG(s.s_acctbal) OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC)) AS balance_change
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartStatistics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    sd.s_name,
    sd.nation_name,
    sd.region_name,
    ps.p_name,
    ps.supplier_count,
    ps.avg_supply_cost,
    ps.supplier_names,
    sd.previous_balance,
    sd.current_balance,
    sd.balance_change
FROM 
    SupplierDetails sd
JOIN 
    PartStatistics ps ON sd.s_suppkey = ps.supplier_count
WHERE 
    sd.balance_change IS NOT NULL
ORDER BY 
    sd.nation_name, ps.avg_supply_cost DESC;
