WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MAX(l.l_shipdate) AS last_ship_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
ActiveCustomers AS (
    SELECT 
        DISTINCT c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.ps_availqty,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    CASE 
        WHEN s.s_acctbal IS NULL THEN 'No Balance Info'
        WHEN s.s_acctbal < 1000 THEN 'Low Balance'
        ELSE 'Healthy Balance'
    END AS account_status,
    (SELECT COUNT(*) FROM OrderStats os WHERE os.total_revenue > 10000) AS high_value_orders,
    r.r_name,
    n.n_name,
    a.total_spent
FROM 
    part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rn = 1
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN ActiveCustomers a ON a.total_spent > (SELECT AVG(total_spent) FROM ActiveCustomers)
WHERE 
    p.p_size BETWEEN 1 AND 5
    AND (p.p_brand LIKE 'Brand%')
    AND (p.p_retailprice IS NOT NULL OR p.p_comment IS NULL)
ORDER BY 
    p.p_partkey ASC, 
    supplier_name DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
