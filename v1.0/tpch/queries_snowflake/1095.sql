
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_by_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
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
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
)
SELECT 
    n.n_name AS Nation_Name,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    SUM(CASE WHEN cs.total_orders > 5 THEN cs.total_spent END) AS total_spent_high_value_customers,
    AVG(ss.total_supply_cost) AS avg_supplier_cost,
    LISTAGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    CustomerOrders cs ON s.s_nationkey = (SELECT n2.n_nationkey FROM nation n2 WHERE n2.n_nationkey = cs.c_custkey)
WHERE 
    ss.rank_by_cost <= 5
GROUP BY 
    n.n_name
ORDER BY 
    total_spent_high_value_customers DESC;
