WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_availqty) DESC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
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
    WHERE 
        o.o_orderdate >= '2023-01-01' OR o.o_orderdate IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    cs.c_custkey,
    cs.c_name,
    COALESCE(ss.total_available_qty, 0) AS available_qty,
    COALESCE(ss.total_supply_cost, 0) AS supply_cost,
    cs.total_orders,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent > 10000 THEN 'Premium'
        WHEN cs.total_spent BETWEEN 5000 AND 10000 THEN 'Standard'
        ELSE 'Basic'
    END AS customer_segment
FROM 
    CustomerOrders cs
FULL OUTER JOIN 
    SupplierSummary ss ON cs.total_orders = ss.rank
WHERE 
    (ss.total_available_qty > 0 OR ss.total_available_qty IS NULL)
    AND (cs.total_orders > 0 OR cs.total_orders IS NULL)
ORDER BY 
    customer_segment, total_spent DESC;
