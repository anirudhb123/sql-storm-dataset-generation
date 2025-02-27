WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rn
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            WHEN p.p_size > 20 THEN 'Large'
            ELSE 'Unknown'
        END AS SizeCategory
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OutlierOrders AS (
    SELECT 
        o.o_orderkey, 
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        COUNT(l.l_orderkey) > 10
),
PriceDetail AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        ps.ps_supplycost, 
        ps.ps_availqty, 
        (ps.ps_supplycost * ps.ps_availqty) AS total_value,
        ROW_NUMBER() OVER (ORDER BY (ps.ps_supplycost * ps.ps_availqty) DESC) AS value_rank
    FROM 
        partsupp ps
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
)
SELECT 
    r.r_name,
    COALESCE(hp.p_name, 'No high-value part') AS high_value_part,
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    SUM(od.line_item_count) AS total_outlier_orders,
    SUM(pd.total_value) AS total_part_value
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = n.n_nationkey
LEFT JOIN 
    HighValueParts hp ON hp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey)
LEFT JOIN 
    CustomerOrders c ON c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT ol.o_orderkey FROM OutlierOrders ol))
LEFT JOIN 
    PriceDetail pd ON pd.value_rank <= 10
GROUP BY 
    r.r_name, hp.p_name, c.c_name
HAVING 
    total_part_value > (SELECT AVG(total_value) FROM PriceDetail) OR (COUNT(rs.s_suppkey) IS NULL)
ORDER BY 
    total_part_value DESC NULLS LAST;
