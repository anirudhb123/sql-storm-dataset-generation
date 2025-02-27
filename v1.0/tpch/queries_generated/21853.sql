WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn,
        p.p_partkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
), 

CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),

HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cs.order_count,
        cs.total_spent,
        cs.avg_order_value
    FROM 
        CustomerOrderStats cs
    JOIN 
        customer c ON cs.c_custkey = c.c_custkey
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderStats)
        AND cs.order_count > 2
)

SELECT 
    hvc.c_custkey,
    hvc.c_name,
    r.r_name AS region_name,
    COALESCE(ps.ps_availqty, 0) AS available_quantity,
    COALESCE(rs.total_spent, 0) AS total_spent,
    CASE 
        WHEN hvc.avg_order_value IS NULL THEN 'N/A'
        ELSE TO_CHAR(hvc.avg_order_value, 'FM$999,999.99')
    END AS formatted_avg_order_value,
    p.p_name,
    p.p_retailprice,
    (SELECT 
         COUNT(DISTINCT r2.n_nationkey) 
     FROM 
         nation r2 
     WHERE 
         r2.n_regionkey = r.r_regionkey
     AND 
         r2.n_name LIKE 'N%') AS nation_count
FROM 
    HighValueCustomers hvc
JOIN 
    region r ON r.r_regionkey = 
        (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = hvc.c_nationkey)
LEFT JOIN 
    partsupp ps ON ps.ps_partkey = 
        (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#23' LIMIT 1)
LEFT JOIN 
    RankedSuppliers rs ON rs.p_partkey = ps.ps_partkey
WHERE 
    hvc.total_spent > COALESCE((SELECT AVG(total_spent) FROM HighValueCustomers), 0)
    AND hvc.c_name NOT IN ('Customer#1', 'Customer#2')
ORDER BY 
    hvc.total_spent DESC, hvc.c_custkey;
