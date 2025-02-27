WITH Supplier_Summary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),

Customer_Orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
),

Nation_Supplier AS (
    SELECT 
        n.n_nationkey, 
        n.n_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
)

SELECT 
    cs.c_name AS customer_name,
    cs.o_orderkey AS order_key,
    cs.o_orderdate AS order_date,
    ss.s_name AS supplier_name,
    ss.total_cost,
    ns.n_name AS nation_name,
    ns.total_supply_value
FROM 
    Customer_Orders cs
LEFT JOIN 
    Supplier_Summary ss ON (ss.part_count > 0)
LEFT JOIN 
    Nation_Supplier ns ON (ns.n_nationkey IS NOT NULL)
WHERE 
    ss.total_cost IS NOT NULL
ORDER BY 
    total_cost DESC, order_date ASC
LIMIT 100;
