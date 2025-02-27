WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        CASE 
            WHEN c.c_acctbal > 1000 THEN 'High'
            WHEN c.c_acctbal BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS value_segment
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
FilteredOrders AS (
    SELECT 
        os.o_orderkey,
        os.total_order_value,
        hc.value_segment
    FROM 
        OrderSummary os
    JOIN 
        orders o ON os.o_orderkey = o.o_orderkey
    JOIN 
        HighValueCustomers hc ON o.o_custkey = hc.c_custkey
    WHERE 
        os.total_order_value > 5000
)
SELECT 
    r.r_name, 
    p.p_name, 
    s.s_name, 
    SUM(case when fs.value_segment = 'High' then fs.total_order_value else 0 end) AS high_value_order_sum,
    COUNT(DISTINCT fs.o_orderkey) AS high_value_order_count
FROM 
    RankedSuppliers s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    FilteredOrders fs ON fs.value_segment = 'High'
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 100
GROUP BY 
    r.r_name, p.p_name, s.s_name
ORDER BY 
    high_value_order_sum DESC, high_value_order_count DESC;
