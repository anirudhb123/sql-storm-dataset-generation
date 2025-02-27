WITH SupplierCost AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 50000
)
SELECT 
    n.n_name AS nation,
    r.r_name AS region,
    COUNT(DISTINCT c.c_custkey) AS high_value_customer_count,
    SUM(COALESCE(sc.total_supply_cost, 0)) AS total_supplier_cost,
    AVG(H.total_spent) AS avg_customer_spent
FROM 
    nation n
INNER JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT OUTER JOIN 
    HighValueCustomers H ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = H.c_custkey)
LEFT OUTER JOIN 
    SupplierCost sc ON sc.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')))
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_supplier_cost DESC, high_value_customer_count DESC;
