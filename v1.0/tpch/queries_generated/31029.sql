WITH RECURSIVE CustomerRank AS (
    SELECT 
        c_custkey,
        c_name,
        SUM(o_totalprice) AS total_expenditure,
        ROW_NUMBER() OVER (ORDER BY SUM(o_totalprice) DESC) AS rank
    FROM 
        customer
    LEFT JOIN 
        orders ON customer.c_custkey = orders.o_custkey
    GROUP BY 
        c_custkey, c_name
), SupplierRating AS (
    SELECT 
        s_suppkey,
        s_name,
        AVG(ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT ps_partkey) AS part_count
    FROM 
        supplier
    JOIN 
        partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
    GROUP BY 
        s_suppkey, s_name
), HighValueSuppliers AS (
    SELECT 
        s_suppkey,
        s_name
    FROM 
        SupplierRating
    WHERE 
        avg_supplycost < (SELECT AVG(avg_supplycost) FROM SupplierRating)
), LineItemStats AS (
    SELECT 
        l_partkey,
        SUM(l_quantity) AS total_quantity,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
        COUNT(DISTINCT l_orderkey) AS order_count
    FROM 
        lineitem
    GROUP BY 
        l_partkey
), PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        ls.total_quantity,
        ls.total_revenue,
        CASE 
            WHEN ls.total_quantity > 1000 THEN 'High Demand'
            WHEN ls.total_quantity BETWEEN 500 AND 999 THEN 'Moderate Demand'
            ELSE 'Low Demand'
        END AS demand_category
    FROM 
        part p
    LEFT JOIN 
        LineItemStats ls ON p.p_partkey = ls.l_partkey
)
SELECT 
    c.rank,
    c.c_name,
    p.p_name,
    p.demand_category,
    COALESCE(s.s_name, 'Not Supplied') AS supplier_name
FROM 
    CustomerRank c
CROSS JOIN 
    PartDetails p
LEFT JOIN 
    HighValueSuppliers s ON s.s_suppkey = (SELECT ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey ORDER BY ps.ps_supplycost LIMIT 1)
WHERE 
    c.rank <= 10 AND 
    p.total_revenue IS NOT NULL
ORDER BY 
    total_revenue DESC;
