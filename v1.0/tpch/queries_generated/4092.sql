WITH SupplierCosts AS (
    SELECT 
        ps.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name,
    COALESCE(SUM(s.total_cost), 0) AS total_supplier_cost,
    COALESCE(COUNT(DISTINCT co.c_custkey), 0) AS customer_count,
    SUM(CASE WHEN co.order_count > 0 THEN co.avg_order_value ELSE 0 END) AS avg_customer_order_value
FROM 
    nation n
LEFT JOIN 
    SupplierCosts s ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = s.s_suppkey)
LEFT JOIN 
    CustomerOrders co ON n.n_nationkey = (SELECT c_nationkey FROM customer WHERE c_custkey = co.c_custkey)
GROUP BY 
    n.n_name
HAVING 
    SUM(s.total_cost) > 10000 OR COUNT(DISTINCT co.c_custkey) > 5
ORDER BY 
    total_supplier_cost DESC, customer_count DESC;
