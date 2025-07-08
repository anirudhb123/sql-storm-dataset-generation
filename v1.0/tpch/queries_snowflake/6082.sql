WITH NationSupplier AS (
    SELECT 
        n.n_name AS nation_name,
        s.s_suppkey AS supplier_key,
        s.s_name AS supplier_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name, s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT
        c.c_custkey AS customer_key,
        c.c_name AS customer_name,
        count(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
AggregatedStats AS (
    SELECT 
        ns.nation_name,
        COUNT(DISTINCT cs.customer_key) AS customer_count,
        SUM(cs.total_spent) AS total_spending,
        SUM(ns.total_supply_cost) AS total_supplier_costs
    FROM 
        NationSupplier ns
    JOIN 
        CustomerOrderStats cs ON ns.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = cs.customer_key))
    GROUP BY 
        ns.nation_name
)
SELECT 
    a.nation_name,
    a.customer_count,
    a.total_spending,
    a.total_supplier_costs,
    ROUND(a.total_spending / NULLIF(a.customer_count, 0), 2) AS avg_spending_per_customer
FROM 
    AggregatedStats a
ORDER BY 
    a.total_spending DESC;
