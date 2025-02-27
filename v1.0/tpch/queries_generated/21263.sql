WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name, 
        s.s_name, 
        s.total_supply_cost
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.rn <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name
),
HighSpenderCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        CASE 
            WHEN total_spent IS NULL THEN 'NOT SPENT'
            WHEN total_spent > (SELECT AVG(total_spent) FROM CustomerOrders) THEN 'HIGH SPENDER'
            ELSE 'LOW SPENDER'
        END AS spending_category
    FROM 
        CustomerOrders c
)
SELECT 
    ts.r_name,
    ts.s_name,
    h.c_name,
    h.spending_category,
    COALESCE(h.order_count, 0) AS order_count,
    COALESCE(h.total_spent, 0.00) AS total_spent,
    COUNT(DISTINCT l.l_orderkey) AS distinct_lineitems,
    AVG(l.l_extendedprice / NULLIF(l.l_quantity, 0)) AS avg_price_per_unit
FROM 
    TopSuppliers ts
LEFT JOIN 
    HighSpenderCustomers h ON h.c_custkey = (SELECT c.c_custkey FROM customer c ORDER BY RANDOM() LIMIT 1)
LEFT JOIN 
    lineitem l ON h.c_custkey = l.l_orderkey
GROUP BY 
    ts.r_name, ts.s_name, h.c_name, h.spending_category
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 0 OR h.spending_category = 'NOT SPENT'
ORDER BY 
    ts.r_name, total_spent DESC, h.spending_category DESC;
