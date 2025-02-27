WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        nation.n_name AS country,
        ROW_NUMBER() OVER (PARTITION BY nation.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation ON s.s_nationkey = nation.n_nationkey
), 
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        COUNT(ps.ps_suppkey) AS supply_count,
        STRING_AGG(s.s_name, ', ') AS supplier_names
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
), 
BestSellingParts AS (
    SELECT 
        l.l_partkey, 
        SUM(l.l_quantity) AS total_quantity_sold
    FROM lineitem l
    GROUP BY l.l_partkey
    ORDER BY total_quantity_sold DESC 
    LIMIT 10
)
SELECT 
    pd.p_name,
    pd.p_brand,
    pd.supply_count,
    pd.supplier_names,
    B.total_quantity_sold,
    rs.country AS supplier_country
FROM PartDetails pd
JOIN BestSellingParts B ON pd.p_partkey = B.l_partkey
JOIN RankedSuppliers rs ON rs.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey = pd.p_partkey 
    ORDER BY ps.ps_supplycost ASC 
    LIMIT 1
)
WHERE rs.rank = 1;
