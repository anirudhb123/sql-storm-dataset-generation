WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2023-12-31'
),
HighValueCustomers AS (
    SELECT 
        c.c_nationkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(RC.top_customer, 'None') AS top_customer,
    COALESCE(RC.total_spent, 0) AS highest_order_value,
    COALESCE(AVG(S.s_acctbal), 0) AS avg_supplier_balance
FROM 
    nation n
LEFT JOIN 
    HighValueCustomers HVC ON n.n_nationkey = HVC.c_nationkey
LEFT JOIN (
    SELECT 
        r.c_nationkey,
        r.c_name AS top_customer,
        r.total_spent
    FROM 
        RankedOrders r
    WHERE 
        r.rn = 1
) RC ON HVC.c_nationkey = RC.c_nationkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
GROUP BY 
    n.n_name, RC.top_customer, RC.total_spent
ORDER BY 
    total_spent DESC NULLS LAST, 
    nation_name;
