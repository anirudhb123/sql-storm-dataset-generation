WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
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
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierStats AS (
    SELECT 
        n.n_name AS nation,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
        AVG(s.s_acctbal) AS avg_acct_bal
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name AS region_name,
    cs.c_name AS customer_name,
    cs.total_orders,
    cs.total_spent,
    ss.nation,
    ss.total_available,
    ss.unique_suppliers,
    ss.avg_acct_bal,
    rs.s_name AS top_supplier_name,
    rs.rank
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rank = 1
LEFT JOIN 
    CustomerOrders cs ON cs.c_custkey = (SELECT TOP 1 c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey ORDER BY c.c_acctbal DESC)
LEFT JOIN 
    SupplierStats ss ON ss.nation = n.n_name
WHERE 
    (ss.total_available > 1000 OR ss.avg_acct_bal IS NULL)
    AND (cs.total_spent > 5000 OR cs.total_orders IS NULL)
ORDER BY 
    r.r_name, cs.total_spent DESC;
