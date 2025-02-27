WITH RankedProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 0
),
TopCostSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(total_cost) FROM (
            SELECT 
                SUM(ps_inner.ps_supplycost * ps_inner.ps_availqty) AS total_cost
            FROM 
                supplier s_inner
            JOIN 
                partsupp ps_inner ON s_inner.s_suppkey = ps_inner.ps_suppkey
            GROUP BY 
                s_inner.s_suppkey
        ) AS avg_cost)
),
FilteredNations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name 
    FROM 
        nation n 
    WHERE 
        n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE '%East%')
)
SELECT 
    c.c_custkey,
    c.c_name,
    SUM(o.o_totalprice) AS total_spent,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT CAST(l.l_status AS VARCHAR), ', ') AS line_statuses,
    t.total_cost AS supplier_total_cost,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) = 0 THEN 'No Orders' 
        ELSE 'Regular Customer' 
    END AS customer_type
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey 
LEFT JOIN 
    TopCostSuppliers t ON l.l_suppkey = t.s_suppkey 
WHERE 
    o.o_orderdate >= DATEADD(year, -1, GETDATE()) AND
    c.c_acctbal IS NOT NULL AND 
    (c.c_mktsegment LIKE 'B%' OR c.c_mktsegment IS NULL)
GROUP BY 
    c.c_custkey, c.c_name, t.total_cost
HAVING 
    SUM(o.o_totalprice) > 
    (SELECT COALESCE(AVG(o_inner.o_totalprice), 0) FROM orders o_inner WHERE o_inner.o_orderdate >= DATEADD(year, -1, GETDATE()))
ORDER BY 
    total_spent DESC NULLS LAST;
