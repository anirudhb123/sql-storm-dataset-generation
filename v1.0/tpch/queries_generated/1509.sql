WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        cust.c_custkey,
        cust.order_count,
        cust.total_spent,
        RANK() OVER (ORDER BY cust.total_spent DESC) AS rank
    FROM 
        CustomerOrders cust
    WHERE 
        cust.total_spent > 1000
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(s.s_name) AS top_supplier
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    n.n_nationkey IN (SELECT DISTINCT s_nationkey FROM RankedSuppliers WHERE rn <= 3)
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC
UNION ALL
SELECT 
    'High Value Customers' AS nation_name,
    SUM(COALESCE(o.o_totalprice, 0)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    NULL AS top_supplier
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    orders o ON hvc.c_custkey = o.o_custkey
WHERE 
    hvc.rank <= 10
GROUP BY 
    hvc.c_custkey
ORDER BY 
    total_revenue DESC;
