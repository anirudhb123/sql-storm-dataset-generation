WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s_name,
        total_avail_quantity,
        avg_supply_cost
    FROM 
        SupplierStats
    WHERE 
        rn = 1
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
    HAVING 
        COUNT(o.o_orderkey) > 0
),
NationSummary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(COALESCE(s.s_acctbal, 0)) AS total_account_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    cs.c_name AS customer_name,
    cs.total_spent,
    ns.n_name AS nation_name,
    ts.s_name AS top_supplier,
    ts.total_avail_quantity,
    ts.avg_supply_cost
FROM 
    CustomerOrders cs
JOIN 
    nation n ON cs.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
JOIN 
    NationSummary ns ON 1=1
LEFT JOIN 
    TopSuppliers ts ON ns.supplier_count > 0
ORDER BY 
    cs.total_spent DESC, ns.supplier_count;
