WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        total_spent > 10000
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_supplycost > 50
),
TopLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey
    HAVING 
        revenue > 5000
)

SELECT 
    CONCAT(c.c_name, ' (', c.c_custkey, ')') AS customer_info,
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    HighValueCustomers c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierPartDetails sp ON l.l_partkey = sp.ps_partkey
LEFT JOIN 
    supplier s ON sp.s_suppkey = s.s_suppkey
WHERE 
    o.o_orderstatus IN ('F', 'O')
AND 
    o.o_orderdate >= DATE '2022-01-01'
GROUP BY 
    c.c_custkey, c.c_name, p.p_name, s.s_name
ORDER BY 
    total_revenue DESC, order_count DESC
LIMIT 10;
