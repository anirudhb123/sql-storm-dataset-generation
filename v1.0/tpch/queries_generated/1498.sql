WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' AND
        o.o_orderdate < '2023-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.o_orderdate,
    COUNT(DISTINCT r.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COALESCE(SUM(ss.total_available_quantity), 0) AS total_supplier_availability,
    SUM(CASE WHEN c.total_spent > 1000 THEN 1 ELSE 0 END) AS high_value_customers
FROM 
    RankedOrders r
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierStats ss ON l.l_suppkey = ss.s_suppkey
LEFT JOIN 
    CustomerOrders c ON r.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
WHERE 
    r.price_rank <= 5
GROUP BY 
    r.o_orderdate
ORDER BY 
    r.o_orderdate DESC;
