WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal 
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_acctbal IS NOT NULL)
),
OrderStats AS (
    SELECT 
        o.o_custkey, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
)
SELECT 
    ns.n_name AS nation_name,
    SUM(DISTINCT ps.ps_availqty) AS total_available_quantity,
    hv.c_name AS high_value_customer,
    os.order_count,
    os.total_spent,
    ROUND(os.avg_order_value, 2) AS average_order_value,
    rs.total_supply_cost,
    CASE 
        WHEN rs.total_supply_cost > 10000 THEN 'High Cost'
        ELSE 'Low Cost'
    END AS supplier_cost_category
FROM 
    nation ns
LEFT JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    HighValueCustomers hv ON s.s_nationkey = hv.c_nationkey
JOIN 
    OrderStats os ON hv.c_custkey = os.o_custkey
JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
WHERE 
    ps.ps_availqty IS NOT NULL
GROUP BY 
    ns.n_name, hv.c_name, os.order_count, os.total_spent, os.avg_order_value, rs.total_supply_cost
ORDER BY 
    supplier_cost_category DESC, total_available_quantity DESC;
