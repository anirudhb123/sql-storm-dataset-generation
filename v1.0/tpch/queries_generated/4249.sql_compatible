
WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        CASE 
            WHEN l.l_returnflag = 'R' THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE_TRUNC('year', '1998-10-01'::date) - INTERVAL '1 year'
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    sp.s_name AS supplier_name,
    SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_income,
    COUNT(DISTINCT od.o_orderkey) AS total_orders,
    AVG(SUM(od.l_extendedprice * (1 - od.l_discount))) OVER (PARTITION BY r.r_name) AS avg_order_amount
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier sp ON n.n_nationkey = sp.s_nationkey
LEFT JOIN 
    OrderDetails od ON sp.s_suppkey = od.l_partkey
JOIN 
    SupplierPerformance spf ON sp.s_suppkey = spf.s_suppkey
WHERE 
    spf.total_available_quantity IS NOT NULL
GROUP BY 
    r.r_name, n.n_name, sp.s_name
HAVING 
    COUNT(DISTINCT od.o_orderkey) > 5
ORDER BY 
    region_name, nation_name, total_orders DESC;
