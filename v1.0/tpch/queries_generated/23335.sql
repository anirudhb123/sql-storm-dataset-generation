WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
AvailableParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COALESCE(ps.ps_availqty, 0) AS available_quantity,
        (p.p_retailprice * COALESCE(ps.ps_availqty, 0)) AS total_retail_value
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_spent,
        c.order_count
    FROM 
        CustomerOrders c
    WHERE 
        c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    r.r_name,
    s.s_name,
    p.p_name,
    p.available_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue' 
    END AS revenue_category
FROM 
    RankedSuppliers s
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    AvailableParts p ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    HighValueCustomers hvc ON o.o_custkey = hvc.c_custkey
GROUP BY 
    r.r_name, s.s_name, p.p_name, p.available_quantity
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    r.r_name, total_revenue DESC;
