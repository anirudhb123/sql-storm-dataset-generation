WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_type
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
    AND 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderstatus
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COALESCE(SUM(oss.net_revenue), 0) AS total_revenue,
    COALESCE(SUM(hvc.c_acctbal), 0) AS total_customer_balance,
    COUNT(DISTINCT rs.s_suppkey) AS top_supplier_count
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    HighValueCustomers hvc ON n.n_nationkey = hvc.c_nationkey
LEFT JOIN 
    OrderSummary oss ON hvc.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderstatus = 'F')
LEFT JOIN 
    RankedSuppliers rs ON rs.supplier_rank = 1
WHERE 
    r.r_name LIKE 'S%'
GROUP BY 
    r.r_name, n.n_name
HAVING 
    SUM(oss.net_revenue) > 
    (SELECT AVG(total_revenue) FROM (
        SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue 
        FROM lineitem l 
        JOIN orders o ON l.l_orderkey = o.o_orderkey 
        GROUP BY o.o_orderkey
    ) AS overall_revenue)
ORDER BY 
    total_revenue DESC;
