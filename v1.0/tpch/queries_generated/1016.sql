WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    AND 
        o.o_orderstatus IN ('O', 'P')
),
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
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
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.o_orderkey, 
    r.o_orderdate, 
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    ss.total_available,
    ss.total_cost,
    r.o_totalprice,
    CASE 
        WHEN r.order_rank = 1 THEN 'Highest Price Order'
        ELSE 'Regular Order'
    END AS order_status,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY r.o_orderdate DESC) AS customer_order_seq
FROM 
    RankedOrders r
LEFT JOIN 
    CustomerOrders c ON r.o_orderkey = c.order_count
LEFT JOIN 
    SupplierStats ss ON ss.total_cost > r.o_totalprice
WHERE 
    r.o_totalprice > (
        SELECT AVG(o.o_totalprice) FROM orders o WHERE o.o_orderdate >= DATE '2023-01-01'
    )
ORDER BY 
    r.o_orderdate DESC, r.o_orderkey;
