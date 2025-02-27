WITH SupplierRanking AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    sr.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    COALESCE(co.avg_order_value, 0) AS avg_order_value,
    sr.total_supply_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierRanking sr ON sr.rank = 1
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey ORDER BY c.c_acctbal DESC LIMIT 1)
WHERE 
    sr.total_supply_cost IS NOT NULL
ORDER BY 
    r.r_name, n.n_name, co.total_spent DESC;
