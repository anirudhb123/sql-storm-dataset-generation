
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
SubqueryTotalPrice AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(CASE WHEN r.r_name IS NOT NULL THEN 1 ELSE 0 END) AS region_count
    FROM 
        nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        SUM(CASE WHEN r.r_name IS NOT NULL THEN 1 ELSE 0 END) > 1
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    COALESCE(tt.total_price, 0) AS total_order_revenue,
    tn.region_count
FROM 
    part p
LEFT JOIN RankedSuppliers s ON s.rnk = 1 AND p.p_partkey IN (
    SELECT 
        ps.ps_partkey 
    FROM 
        partsupp ps 
    WHERE 
        ps.ps_availqty > (
            SELECT 
                AVG(ps2.ps_availqty) 
            FROM 
                partsupp ps2 
            WHERE 
                ps2.ps_partkey = p.p_partkey
        )
) 
LEFT JOIN SubqueryTotalPrice tt ON tt.o_orderkey = (
    SELECT 
        o_orderkey 
    FROM 
        orders 
    ORDER BY 
        o_orderdate DESC 
    FETCH FIRST 1 ROW ONLY
)
JOIN TopNations tn ON tn.n_nationkey = (
    SELECT 
        c.c_nationkey 
    FROM 
        customer c 
    WHERE 
        c.c_custkey = (
            SELECT 
                o.o_custkey 
            FROM 
                orders o 
            WHERE 
                o.o_orderkey = tt.o_orderkey
        )
)
WHERE 
    p.p_size BETWEEN 1 AND 50 
    AND p.p_comment IS NOT NULL 
    AND (p.p_container LIKE 'SMALL%' OR p.p_container IS NULL)
ORDER BY 
    total_order_revenue DESC, 
    p.p_name ASC;
