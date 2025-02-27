WITH SupplierPart AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        p.p_brand,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_retailprice,
        (p.p_retailprice - ps.ps_supplycost) AS profit_margin,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY (p.p_retailprice - ps.ps_supplycost) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        SUM(ps.ps_availqty) AS total_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) OVER (PARTITION BY c.c_custkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
MaxOrderByCustomer AS (
    SELECT 
        c.c_custkey,
        MAX(o.total_spent) AS max_spent
    FROM 
        CustomerOrders o
    GROUP BY 
        c.c_custkey
)
SELECT 
    sp.s_name AS supplier_name,
    sp.p_name AS part_name,
    sp.profit_margin,
    c.c_name AS customer_name,
    co.order_count,
    co.total_spent
FROM 
    SupplierPart sp
LEFT JOIN 
    HighValueSuppliers hvs ON sp.s_suppkey = hvs.s_suppkey
JOIN 
    CustomerOrders co ON co.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey IN (
            SELECT c.c_custkey 
            FROM customer c 
            WHERE c.c_nationkey IS NOT NULL
        )
    )
WHERE 
    sp.rn = 1 
    AND hvs.total_qty > 50
    AND sp.profit_margin > 0
ORDER BY 
    sp.profit_margin DESC,
    co.total_spent DESC;
