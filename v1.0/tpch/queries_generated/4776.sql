WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN DATEADD(month, -12, GETDATE()) AND GETDATE()
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey, p.p_name
)
SELECT
    c.c_name AS customer_name,
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COALESCE(si.total_available, 0) AS available_quantity,
    CASE 
        WHEN r.order_rank = 1 THEN 'Highest'
        WHEN r.order_rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS order_category
FROM 
    RankedOrders r
JOIN 
    HighValueCustomers c ON r.o_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    lineitem l ON l.l_orderkey = r.o_orderkey
INNER JOIN 
    SupplierPartInfo si ON si.p_partkey = l.l_partkey
LEFT JOIN 
    part p ON p.p_partkey = l.l_partkey
LEFT JOIN 
    supplier s ON s.s_suppkey = l.l_suppkey
WHERE 
    r.o_totalprice > 500 AND (s.s_name IS NOT NULL)
ORDER BY 
    customer_name, r.o_orderdate DESC;
