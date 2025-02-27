WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartsSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_qty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)

SELECT 
    c.c_name AS customer_name,
    COALESCE(CAST(SUM(l.l_extendedprice * (1 - l.l_discount)) AS decimal(12, 2)), 0) AS total_revenue,
    ps.total_qty AS part_quantity,
    ps.avg_supplycost AS avg_cost,
    rs.s_name AS supplier_name,
    rs.s_acctbal AS supplier_balance
FROM 
    CustomerOrders c
LEFT JOIN 
    lineitem l ON c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey)
LEFT JOIN 
    PartsSummary ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON c.c_custkey = ls.l_suppkey
WHERE 
    c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders) 
    AND (rs.s_acctbal IS NOT NULL OR ps.total_qty IS NOT NULL)
GROUP BY 
    c.c_name, ps.total_qty, ps.avg_supplycost, rs.s_name, rs.s_acctbal
ORDER BY 
    total_revenue DESC,
    c.c_name;
