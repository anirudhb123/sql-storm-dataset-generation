WITH RankedSuppliers AS (
    SELECT 
        s.n_nationkey,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        ps.ps_partkey
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 2
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_lines,
        AVG(l.l_quantity) AS avg_quantity,
        CASE 
            WHEN COUNT(l.l_orderkey) > 10 THEN 'High Value' 
            ELSE 'Low Value' 
        END AS order_category
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE((SELECT MAX(total_value) FROM HighValueParts hvp WHERE hvp.ps_partkey = p.p_partkey), 0) AS max_supply_value,
    (SELECT COUNT(DISTINCT n.n_nationkey) FROM nation n JOIN RankedSuppliers rs ON n.n_nationkey = rs.n_nationkey WHERE rs.rank <= 3) AS unique_nations_count,
    os.total_revenue,
    os.order_category,
    CASE 
        WHEN p.p_retailprice IS NULL THEN 'Price Not Available'
        ELSE CONCAT('Price: $', CAST(p.p_retailprice AS VARCHAR))
    END AS retail_price_info
FROM 
    part p
LEFT JOIN 
    OrderStats os ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps)
ORDER BY 
    p.p_partkey DESC
LIMIT 50;
