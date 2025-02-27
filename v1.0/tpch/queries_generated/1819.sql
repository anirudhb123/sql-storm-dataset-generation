WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' 
        AND o.o_orderdate < '2024-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
    HAVING 
        SUM(o.o_totalprice) > 10000
),
CustomerSupplier AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        s.s_name,
        s.s_suppkey
    FROM 
        customer c
    LEFT JOIN 
        supplier s ON c.c_nationkey = s.s_nationkey
)
SELECT 
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    COALESCE(ss.total_available, 0) AS available_quantity,
    (CASE WHEN hvo.total_spent IS NULL THEN 'No Spend' ELSE 'Spent' END) AS spending_status,
    COUNT(ro.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    CustomerSupplier c
LEFT JOIN 
    SupplierStats ss ON c.s_suppkey = ss.s_suppkey
LEFT JOIN 
    HighValueOrders hvo ON c.c_custkey = hvo.o_custkey
JOIN 
    RankedOrders ro ON c.c_custkey = ro.o_orderkey
JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
WHERE 
    c.c_name IS NOT NULL
    AND ss.part_count > 5
GROUP BY 
    c.c_name, s.s_name, ss.total_available, hvo.total_spent
HAVING 
    COUNT(ro.o_orderkey) > 0
ORDER BY 
    total_revenue DESC;
