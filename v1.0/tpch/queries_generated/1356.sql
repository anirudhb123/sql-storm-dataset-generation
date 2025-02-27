WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
Ranking AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    r.o_orderkey,
    r.o_custkey,
    sp.s_name,
    sp.total_parts,
    sp.total_cost,
    CASE 
        WHEN r.order_rank = 1 THEN 'Highest Value Order'
        ELSE 'Regular Order'
    END AS order_type
FROM 
    Ranking r
LEFT JOIN 
    HighValueOrders hvo ON r.o_orderkey = hvo.o_orderkey
JOIN 
    SupplierParts sp ON r.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_custkey = r.o_custkey AND c.c_nationkey = sp.s_suppkey)
WHERE 
    sp.total_parts IS NOT NULL AND
    r.order_rank <= 5
ORDER BY 
    sp.total_cost DESC, 
    r.o_orderkey ASC;
