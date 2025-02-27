WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spending
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL 
)
SELECT 
    r.r_name,
    COUNT(DISTINCT cu.c_custkey) AS num_customers,
    SUM(cu.total_spending) AS total_spending,
    SUM(CASE WHEN rs.rank = 1 THEN rs.total_supply_cost ELSE 0 END) AS top_supplier_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customerorders cu ON cu.c_custkey IN (SELECT c.c_custkey FROM highvaluecustomers c WHERE c.rank <= 10)
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp))
    AND rs.rank <= 5
)
GROUP BY 
    r.r_name
HAVING 
    total_spending > (
        SELECT 
            AVG(total_spending) 
        FROM 
            CustomerOrders
    )
ORDER BY 
    total_spending DESC;
