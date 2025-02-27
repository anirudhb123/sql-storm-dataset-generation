WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
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
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
NationSummary AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers, 
        SUM(total_supply_cost) AS total_supplier_cost
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierCosts sc ON s.s_suppkey = sc.s_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    n.n_name AS nation_name, 
    n.unique_suppliers, 
    n.total_supplier_cost, 
    c.c_name AS top_customer_name, 
    c.order_count, 
    c.total_spent
FROM 
    NationSummary n
JOIN 
    CustomerOrders c ON n.n_nationkey = (
        SELECT 
            n2.n_nationkey 
        FROM 
            customer c2 
        JOIN 
            nation n2 ON c2.c_nationkey = n2.n_nationkey 
        WHERE 
            c2.c_custkey = c.c_custkey 
        ORDER BY 
            c2.c_acctbal DESC 
        LIMIT 1
    )
ORDER BY 
    n.total_supplier_cost DESC, 
    c.total_spent DESC
LIMIT 10;
