WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_name,
        p.p_brand,
        p.p_retailprice
    FROM 
        RankedSuppliers s
    JOIN 
        part p ON p.p_partkey = s.ps_partkey
    WHERE 
        s.rn <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(ROUND(l.l_quantity * l.l_extendedprice * (1 - l.l_discount), 2)) as total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
    HAVING 
        total_spent > 1000
)
SELECT 
    cu.c_name AS customer_name,
    su.s_name AS supplier_name,
    pa.p_name AS part_name,
    SUM(cuo.total_spent) AS total_spent,
    COUNT(DISTINCT cuo.o_orderkey) AS order_count,
    AVG(pa.p_retailprice) AS avg_part_price
FROM 
    TopSuppliers su
JOIN 
    part pa ON pa.p_partkey = su.ps_partkey
JOIN 
    CustomerOrders cuo ON cuo.o_orderkey = cuo.o_orderkey
JOIN 
    customer cu ON cu.c_custkey = cuo.c_custkey
GROUP BY 
    cu.c_name, su.s_name, pa.p_name
ORDER BY 
    total_spent DESC, order_count DESC
LIMIT 10;
