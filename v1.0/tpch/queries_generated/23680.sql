WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_size,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'Undefined Size'
            WHEN p.p_size < 10 THEN 'Small Part'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium Part'
            ELSE 'Large Part' 
        END AS size_category
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, c.c_custkey, c.c_mktsegment
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE 
            WHEN COALESCE(s.s_acctbal, 0) > 5000 THEN 1 
            ELSE 0 
        END) AS high_balance_suppliers,
    AVG(l.total_revenue) AS average_order_revenue,
    STRING_AGG(DISTINCT fp.size_category, ', ') AS part_sizes
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    CustomerOrders l ON l.c_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = n.n_nationkey 
        AND c.c_mktsegment LIKE 'B%'
    )
LEFT JOIN 
    FilteredParts fp ON fp.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey = s.s_suppkey
    )
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    nation_name ASC;
