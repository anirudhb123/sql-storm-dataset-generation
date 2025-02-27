WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
FilteredSuppliers AS (
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
OrderLineDetails AS (
    SELECT 
        l.l_orderkey,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATEADD(DAY, -30, GETDATE())
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o_totalprice,
    c.c_name AS customer_name,
    f.s_name AS supplier_name,
    d.total_sales,
    d.unique_parts
FROM 
    RankedOrders o
LEFT JOIN 
    FilteredSuppliers f ON f.total_supply_cost > (
        SELECT AVG(total_supply_cost) FROM FilteredSuppliers
    )
JOIN 
    OrderLineDetails d ON o.o_orderkey = d.l_orderkey
WHERE 
    o.order_rank = 1 
    AND o.o_totalprice > (SELECT AVG(o_totalprice) FROM RankedOrders) 
ORDER BY 
    o.o_orderdate DESC
LIMIT 100;
