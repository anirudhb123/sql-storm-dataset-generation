WITH SupplierAggregates AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS returned_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey AND l.l_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), HighValueSuppliers AS (
    SELECT 
        sa.s_suppkey, 
        sa.s_name, 
        sa.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY sa.total_supply_cost DESC) AS rank
    FROM 
        SupplierAggregates sa
    WHERE 
        sa.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierAggregates)
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'N/A' 
            ELSE CAST(p.p_size AS VARCHAR)
        END AS size_string,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
FinalOutput AS (
    SELECT 
        hs.s_name AS supplier_name,
        pd.p_name AS part_name,
        pd.p_retailprice,
        pd.size_string,
        hs.total_supply_cost,
        hs.returned_orders
    FROM 
        HighValueSuppliers hs
    CROSS JOIN 
        PartDetails pd
    WHERE 
        pd.price_rank <= 5
        AND pd.p_retailprice > hs.total_supply_cost * 0.1
)
SELECT 
    f.supplier_name, 
    f.part_name, 
    f.p_retailprice, 
    f.size_string, 
    f.total_supply_cost,
    COALESCE(f.returned_orders, 0) AS returned_orders
FROM 
    FinalOutput f
ORDER BY 
    f.total_supply_cost DESC, 
    f.p_retailprice ASC
LIMIT 50;
