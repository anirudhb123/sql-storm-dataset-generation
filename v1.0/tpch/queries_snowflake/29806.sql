
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(p.p_retailprice) AS avg_price
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        LENGTH(p.p_name) > 10
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ps.s_name AS supplier_name,
    pp.total_available_qty AS available_quantity,
    pp.avg_price AS average_price,
    co.total_spent AS customer_total_spent,
    co.last_order_date AS last_order_date,
    r.r_name AS region_name
FROM 
    RankedSuppliers ps
JOIN 
    FilteredParts pp ON ps.s_suppkey IN (
        SELECT ps2.ps_suppkey 
        FROM partsupp ps2 
        WHERE ps2.ps_partkey = pp.p_partkey
    )
JOIN 
    nation n ON ps.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    CustomerOrders co ON co.c_custkey = ps.s_nationkey
WHERE 
    ps.supplier_rank = 1
ORDER BY 
    co.total_spent DESC, co.last_order_date DESC;
