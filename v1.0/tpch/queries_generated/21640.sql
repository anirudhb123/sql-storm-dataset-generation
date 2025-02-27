WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
),
SupplierParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        COALESCE(NULLIF(ps.ps_availqty, 0), 1) AS available_quantity -- Handle division by zero
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        SUM(CASE 
                WHEN o.o_orderstatus = 'O' THEN o.o_totalprice 
                ELSE 0 
            END) AS total_orders,
        COUNT(o.o_orderkey) AS total_order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(s.ps_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders_count,
    SUM(CASE 
            WHEN RANKED.order_rank = 1 THEN 1 
            ELSE 0 
        END) AS top_orders_count,
    SUM(NULLIF(c.total_orders, 0)) AS non_zero_order_values
FROM 
    nation n
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    SupplierParts s ON s.ps_availqty >= 10
LEFT JOIN 
    RankedOrders RANKED ON RANKED.o_orderkey = o.o_orderkey
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    customer_count DESC NULLS LAST;
