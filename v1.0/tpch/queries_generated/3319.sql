WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.order_count,
        co.total_spent,
        CASE 
            WHEN co.total_spent IS NULL THEN 'No Orders'
            WHEN co.total_spent > 10000 THEN 'High'
            ELSE 'Low' 
        END AS customer_value
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        co.order_count IS NULL OR co.order_count > 5
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS number_of_suppliers,
    COUNT(DISTINCT c.c_custkey) AS number_of_customers,
    AVG(s.total_supply_cost) AS avg_supply_cost,
    SUM(CASE WHEN h.customer_value = 'High' THEN 1 ELSE 0 END) AS high_value_customer_count
FROM 
    RankedSuppliers s
JOIN 
    nation n ON s.n_regionkey = n.n_nationkey
LEFT JOIN 
    HighValueCustomers h ON h.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
GROUP BY 
    n.n_name
ORDER BY 
    SUM(s.total_supply_cost) DESC;
