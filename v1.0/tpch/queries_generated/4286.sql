WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
TotalOrders AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        o.o_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(to.total_orders, 0) AS total_orders,
        COALESCE(to.total_spent, 0.00) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        TotalOrders to ON c.c_custkey = to.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
PartPerformance AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_extendedprice) AS avg_extended_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_quantity) > 100
)
SELECT 
    hvc.c_name,
    hvc.total_orders,
    hvc.total_spent,
    ps.p_name,
    pp.total_quantity,
    pp.avg_extended_price,
    rs.s_name AS top_supplier
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    PartPerformance pp ON hvc.total_spent > 5000
LEFT JOIN 
    RankedSuppliers rs ON rs.rank = 1
WHERE 
    hvc.total_orders >= 5
ORDER BY 
    hvc.total_spent DESC, pp.total_quantity DESC
LIMIT 10;
