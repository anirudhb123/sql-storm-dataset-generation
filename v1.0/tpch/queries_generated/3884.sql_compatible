
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_discount) AS avg_discount,
        MAX(l.l_extendedprice) AS max_price
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    co.c_name,
    SUM(l.total_quantity) AS order_quantity,
    SUM(l.max_price) AS total_value,
    s.s_name AS supplier_name,
    CASE 
        WHEN co.total_orders IS NULL THEN 'No Orders'
        ELSE CAST(co.total_orders AS VARCHAR) 
    END AS order_count,
    ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY SUM(l.max_price) DESC) AS rn
FROM 
    CustomerOrders co
LEFT JOIN 
    LineItemStats l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
LEFT JOIN 
    RankedSuppliers s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 100.00))
LEFT JOIN 
    nation n ON n.n_nationkey = co.c_custkey
WHERE 
    n.n_name LIKE 'A%'
GROUP BY 
    co.c_name, s.s_name, co.total_orders, co.c_custkey
HAVING 
    SUM(l.max_price) > 5000
ORDER BY 
    order_quantity DESC, rn;
