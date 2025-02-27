WITH CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighSpenders AS (
    SELECT 
        c.c_custkey,
        c.c_name
    FROM 
        CustomerOrderStats cos
    WHERE 
        cos.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderStats)
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100
)
SELECT 
    h.c_custkey,
    h.c_name,
    tp.p_partkey,
    tp.p_name,
    ps.total_available_quantity,
    ps.avg_supply_cost,
    CASE 
        WHEN ps.total_available_quantity IS NULL THEN 'Out of stock' 
        ELSE 'In stock' 
    END AS stock_status
FROM 
    HighSpenders h
JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = h.c_custkey)
JOIN 
    TopParts tp ON l.l_partkey = tp.p_partkey
LEFT JOIN 
    PartSupplierStats ps ON tp.p_partkey = ps.ps_partkey
WHERE 
    h.c_custkey IS NOT NULL
ORDER BY 
    h.c_custkey, tp.p_partkey;
