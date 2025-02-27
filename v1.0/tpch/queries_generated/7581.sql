WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderLineTotals AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(olt.total_line_value) AS grand_total_sales,
    SUM(sps.total_supply_value) AS total_supply_value,
    SUM(sps.total_available_quantity) AS total_available_quantity
FROM 
    nation n
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    OrderLineTotals olt ON o.o_orderkey = olt.o_orderkey
LEFT JOIN 
    SupplierStats sps ON sps.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN part p ON ps.ps_partkey = p.p_partkey WHERE p.p_size > 10)
WHERE 
    n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'EUROPE')
GROUP BY 
    n.n_name
ORDER BY 
    grand_total_sales DESC
LIMIT 10;
