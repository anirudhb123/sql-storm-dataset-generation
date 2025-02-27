
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate <= DATE '1997-12-31'
),
SupplierPartData AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStatus AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    sp.s_name,
    sp.total_available,
    sp.average_supply_cost,
    co.c_name,
    co.total_orders,
    co.total_spent
FROM 
    RankedOrders r
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierPartData sp ON l.l_suppkey = sp.s_suppkey
LEFT JOIN 
    CustomerOrderStatus co ON EXISTS (SELECT 1 FROM orders o WHERE o.o_custkey = co.c_custkey AND o.o_orderkey = r.o_orderkey)
WHERE 
    r.order_rank <= 10 
    AND (sp.average_supply_cost IS NULL OR sp.total_available > 0)
ORDER BY 
    r.o_totalprice DESC;
