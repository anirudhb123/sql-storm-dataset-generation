WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN c.c_acctbal < 5000 THEN 'Low Value'
            WHEN c.c_acctbal BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'High Value' 
        END AS value_segment
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_items,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
NationRegions AS (
    SELECT 
        n.n_nationkey,
        r.r_name,
        COUNT(*) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_nationkey, r.r_name
)
SELECT 
    p.p_name,
    s.s_name,
    c.c_name AS customer_name,
    os.total_revenue,
    os.total_items,
    os.avg_quantity,
    CASE 
        WHEN nr.supplier_count > 10 THEN 'Diverse Supply'
        ELSE 'Limited Supply' 
    END AS supply_diversity,
    hvc.value_segment
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    orders o ON s.s_suppkey = o.o_custkey
JOIN 
    OrderStats os ON o.o_orderkey = os.o_orderkey
JOIN 
    HighValueCustomers hvc ON o.o_custkey = hvc.c_custkey
LEFT JOIN 
    NationRegions nr ON s.s_nationkey = nr.n_nationkey
WHERE 
    hvc.value_segment != 'Low Value'
    AND os.avg_quantity IS NOT NULL
    AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL)
ORDER BY 
    total_revenue DESC, 
    supply_diversity, 
    customer_name;
