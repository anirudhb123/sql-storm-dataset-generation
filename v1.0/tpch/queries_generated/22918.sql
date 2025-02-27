WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    c.c_name,
    COALESCE(hp.total_value, 0) AS part_value,
    ss.s_name AS supplier_name,
    COALESCE(ss.rank, 0) AS supplier_rank
FROM 
    CustomerOrders c
LEFT JOIN 
    HighValueParts hp ON hp.p_partkey = ANY (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM RankedSuppliers s WHERE s.rank <= 5))
LEFT JOIN 
    RankedSuppliers ss ON ss.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = (SELECT DISTINCT n2.n_name FROM nation n2 WHERE n2.n_nationkey = c.c_nationkey))
WHERE 
    (c.c_name LIKE 'A%' OR c.c_name LIKE '%B%') 
    AND (supplier_rank IS NULL OR supplier_rank BETWEEN 1 AND 3)
ORDER BY 
    c.c_name, supplier_rank DESC;
