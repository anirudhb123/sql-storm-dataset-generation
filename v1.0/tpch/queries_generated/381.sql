WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopOrders AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.order_count,
        co.total_spent,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS order_rank
    FROM 
        CustomerOrders co
    WHERE 
        co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),
FinalBenchmark AS (
    SELECT 
        ts.c_name AS customer_name,
        ts.total_spent,
        ps.p_name AS product_name,
        ps.total_quantity_sold,
        r.total_cost AS supplier_cost
    FROM 
        TopOrders ts
    JOIN 
        PartDetails ps ON ts.order_count > 5
    LEFT JOIN 
        RankedSuppliers r ON r.rank <= 10
)
SELECT 
    customer_name,
    total_spent,
    product_name,
    total_quantity_sold,
    COALESCE(supplier_cost, 0) AS supplier_cost
FROM 
    FinalBenchmark
ORDER BY 
    total_spent DESC, product_name ASC
LIMIT 50;
