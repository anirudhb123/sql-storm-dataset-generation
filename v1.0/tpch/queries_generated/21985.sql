WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
),
NullLogicTest AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(li.l_quantity), 0) AS total_quantity,
        SUM(CASE WHEN li.l_discount IS NULL THEN 0 ELSE li.l_discount END) AS total_discount,
        SUM(p.p_retailprice) / NULLIF(COUNT(li.l_partkey), 0) AS avg_retailprice
    FROM 
        part p
    LEFT JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    WHERE 
        p.p_retailprice > 100 
        OR (p.p_name LIKE '%special%' AND p.p_size BETWEEN 1 AND 10)
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    c.c_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    pn.total_quantity,
    ct.total_revenue,
    rt.total_parts
FROM 
    CustomerOrders ct
LEFT JOIN 
    RankedSuppliers rt ON ct.c_custkey = rt.s_nationkey
FULL OUTER JOIN 
    NullLogicTest pn ON ct.o_orderkey = pn.p_partkey
LEFT JOIN 
    supplier s ON rt.s_nationkey = s.s_nationkey
WHERE 
    (c.c_custkey IS NOT NULL AND s.s_name IS NOT NULL)
    OR (ct.total_revenue > 1000 AND pn.total_quantity = 0)
ORDER BY 
    ct.total_revenue DESC NULLS LAST, 
    pn.total_quantity ASC, 
    s.s_name;
