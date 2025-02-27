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
        AND o.o_orderdate <= DATE '2023-12-31'
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
CustomerSpend AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(cs.total_spent, 0) AS customer_spending,
    CASE 
        WHEN r.o_orderstatus = 'F' THEN 'Finished'
        WHEN r.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Unknown'
    END AS order_status,
    si.total_supply_cost
FROM 
    RankedOrders r
LEFT JOIN 
    CustomerSpend cs ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name ILIKE '%' || r.o_orderkey || '%' LIMIT 1)
LEFT JOIN 
    SupplierInfo si ON si.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem l ON ps.ps_partkey = l.l_partkey WHERE l.l_orderkey = r.o_orderkey LIMIT 1)
WHERE 
    si.total_supply_cost IS NOT NULL
ORDER BY 
    r.o_orderdate DESC
LIMIT 50;
