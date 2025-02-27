WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank 
    FROM 
        orders o 
    WHERE 
        o.o_orderdate >= '2023-01-01' 
        AND o.o_orderdate < '2023-12-31'
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        MIN(ps.ps_supplycost) AS min_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name,
    p.p_name,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    COALESCE(SUM(l.l_extendedprice), 0) AS total_revenue,
    CASE 
        WHEN COALESCE(SUM(l.l_extendedprice), 0) > 10000 THEN 'High Revenue'
        WHEN COALESCE(SUM(l.l_extendedprice), 0) BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue' 
    END AS revenue_category,
    (SELECT AVG(total_spent)
     FROM CustomerOrders) AS avg_customer_spending
FROM 
    lineitem l
JOIN 
    RankedOrders ro ON l.l_orderkey = ro.o_orderkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_regionkey IS NOT NULL
GROUP BY 
    n.n_name, p.p_name
HAVING 
    COUNT(DISTINCT ro.o_orderkey) > 2
    AND (SUM(l.l_discount) / NULLIF(SUM(l.l_extendedprice), 0)) < 0.1
ORDER BY 
    total_revenue DESC
LIMIT 10
UNION ALL
SELECT 
    'TOTAL' AS n_name,
    NULL AS p_name,
    SUM(COALESCE(total_quantity, 0)),
    SUM(COALESCE(total_revenue, 0)),
    NULL,
    NULL
FROM 
    (SELECT 
        COALESCE(SUM(total_quantity), 0) AS total_quantity,
        COALESCE(SUM(total_revenue), 0) AS total_revenue 
     FROM (
        SELECT 
            n_name,
            COALESCE(SUM(l_quantity), 0) AS total_quantity,
            COALESCE(SUM(l_extendedprice), 0) AS total_revenue
        FROM 
            lineitem l
        JOIN 
            RankedOrders ro ON l.l_orderkey = ro.o_orderkey
        JOIN 
            part p ON l.l_partkey = p.p_partkey
        LEFT JOIN 
            supplier s ON l.l_suppkey = s.s_suppkey
        JOIN 
            nation n ON s.s_nationkey = n.n_nationkey
        GROUP BY 
            n_name
     ) AS revenue_table
    ) AS final_totals;
