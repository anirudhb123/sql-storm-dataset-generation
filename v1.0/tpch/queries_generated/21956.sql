WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
    AND 
        s.s_comment NOT LIKE '%deprecated%'
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
ActiveCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal > 1000 THEN 'Premium'
            WHEN c.c_acctbal BETWEEN 500 AND 1000 THEN 'Standard'
            ELSE 'Basic'
        END AS cust_type
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(r.r_name, 'Unknown Region') AS region_name,
    COALESCE(ac.cust_type, 'No Customer') AS customer_type,
    COUNT(DISTINCT fo.o_orderkey) AS order_count,
    SUM(COALESCE(rs.s_acctbal, 0)) AS total_supplier_balance
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    region r ON s.s_nationkey = r.r_regionkey
LEFT JOIN 
    FilteredOrders fo ON fo.o_custkey IN (SELECT c.c_custkey FROM ActiveCustomers ac WHERE ac.cust_type = 'Premium')
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rn <= 3
LEFT JOIN 
    ActiveCustomers ac ON fo.o_custkey = ac.c_custkey
WHERE 
    p.p_retailprice > 20.00
GROUP BY 
    p.p_partkey, p.p_name, r.r_name, ac.cust_type
HAVING 
    COUNT(DISTINCT fo.o_orderkey) > 5
ORDER BY 
    total_supplier_balance DESC, p.p_name ASC;
