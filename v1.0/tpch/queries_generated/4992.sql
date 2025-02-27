WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TotalOrderValue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
HighValueOrders AS (
    SELECT 
        tv.o_orderkey,
        tv.total_value,
        ROW_NUMBER() OVER (ORDER BY tv.total_value DESC) AS order_rank
    FROM 
        TotalOrderValue tv
    WHERE 
        tv.total_value > 10000
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    r.r_name AS region_name,
    COALESCE(hv.total_value, 0) AS high_value_order_amount,
    CASE 
        WHEN hv.order_rank IS NOT NULL THEN 'High Value'
        ELSE 'Regular'
    END AS order_type
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    region r ON s.nation_name = (
        SELECT n.n_name 
        FROM nation n 
        WHERE n.n_nationkey = s.n_nationkey
    )
LEFT JOIN 
    HighValueOrders hv ON hv.o_orderkey = ps.ps_partkey 
WHERE 
    (p.p_retailprice < 20.00 OR p.p_brand LIKE 'Brand%')
ORDER BY 
    p.p_name, 
    supplier_name;
