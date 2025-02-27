WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighPriorityOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS number_of_customers,
    COALESCE(SUM(ho.total_price_after_discount), 0) AS total_order_values,
    COALESCE(SUM(rs.total_supply_cost), 0) AS total_supply_costs,
    CASE 
        WHEN COUNT(DISTINCT c.c_custkey) > 10 THEN 'Major Market' 
        ELSE 'Minor Market' 
    END AS market_segment
FROM 
    nation n
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    HighPriorityOrders ho ON ho.o_orderkey IN (
        SELECT DISTINCT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
    )
LEFT JOIN 
    RankedSuppliers rs ON rs.s_nationkey = n.n_nationkey AND rs.rank = 1
GROUP BY 
    n.n_name
ORDER BY 
    total_order_values DESC, number_of_customers DESC;
