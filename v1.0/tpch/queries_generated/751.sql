WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
),
SupplierPart AS (
    SELECT 
        ps.ps_partkey, 
        s.s_suppkey, 
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
),
CustomerSpending AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    AVG(sp.total_spent) AS avg_customer_spending,
    CASE 
        WHEN COUNT(DISTINCT ps.ps_suppkey) IS NULL THEN 'No suppliers'
        ELSE CAST(COUNT(DISTINCT ps.ps_suppkey) AS VARCHAR)
    END AS supplier_info,
    STRING_AGG(CONVERT(VARCHAR, o.o_orderkey), ', ') AS order_keys
FROM 
    part p
LEFT JOIN 
    SupplierPart ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    CustomerSpending sp ON sp.c_custkey IN (
        SELECT c.c_custkey
        FROM orders o
        JOIN customer c ON o.o_custkey = c.c_custkey
        WHERE o.o_orderkey IN (SELECT o_orderkey FROM RankedOrders WHERE rn <= 5)
    )
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    p.p_name
HAVING 
    SUM(ps.total_avail_qty) > 100
ORDER BY 
    avg_customer_spending DESC
