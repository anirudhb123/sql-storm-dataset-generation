WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
), 
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        p.p_size, 
        COUNT(ps.ps_supplycost) AS supply_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice, p.p_size
    HAVING 
        COUNT(ps.ps_supplycost) > 0
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate > '2023-01-01' 
        AND (l.l_returnflag IS NULL OR l.l_returnflag <> 'Y')
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name,
    SUM(COALESCE(o.net_revenue, 0)) AS total_revenue,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    CASE 
        WHEN SUM(COALESCE(o.net_revenue, 0)) > 100000 THEN 'High'
        WHEN SUM(COALESCE(o.net_revenue, 0)) BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category
FROM 
    nation n 
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    (SELECT 
        od.o_orderkey,
        od.net_revenue
    FROM 
        OrderDetails od
    JOIN 
        RankedSuppliers rs ON od.o_orderkey = rs.s_suppkey
    ) o ON c.c_custkey = o.o_orderkey
LEFT JOIN 
    RankedSuppliers rs ON c.c_nationkey = rs.s_suppkey
WHERE 
    (n.n_name LIKE 'A%' OR n.n_name LIKE 'B%')
    AND rs.rn <= 3
GROUP BY 
    n.n_name
HAVING 
    total_revenue > 0
ORDER BY 
    total_revenue DESC;
