WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
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
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_discount) AS avg_discount
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ns.n_name AS supplier_nation,
    cs.c_name AS customer_name,
    ss.s_name AS supplier_name,
    co.total_orders,
    co.total_spent,
    la.total_revenue,
    la.avg_discount
FROM 
    nation ns
LEFT JOIN 
    supplier ss ON ns.n_nationkey = ss.s_nationkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = 
        (SELECT c.c_custkey 
         FROM customer c 
         WHERE c.c_nationkey = ns.n_nationkey 
         ORDER BY c.c_acctbal DESC 
         LIMIT 1)
LEFT JOIN 
    LineItemAnalysis la ON la.l_orderkey = 
        (SELECT o.o_orderkey 
         FROM orders o 
         WHERE o.o_custkey = co.c_custkey 
         ORDER BY o.o_orderdate DESC 
         LIMIT 1)
WHERE 
    ss.s_name IS NOT NULL 
ORDER BY 
    total_spent DESC, 
    supplier_nation, 
    customer_name;
