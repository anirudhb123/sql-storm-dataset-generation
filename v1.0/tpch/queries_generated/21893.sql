WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_manufacturer,
        AVG(l.l_extendedprice) AS avg_extended_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice, p.p_manufacturer
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N' AND l.l_discount BETWEEN 0.05 AND 0.15
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COUNT(DISTINCT od.o_orderkey) AS total_orders,
    SUM(od.total_price) AS grand_total_sales,
    COUNT(DISTINCT hp.p_partkey) AS high_value_part_count,
    MAX(rnk) AS max_rank_supplier
FROM 
    region r
LEFT JOIN 
    nation ns ON ns.n_regionkey = r.r_regionkey
LEFT JOIN 
    customer c ON c.c_nationkey = ns.n_nationkey
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey
LEFT JOIN 
    OrderDetails od ON od.o_orderkey = o.o_orderkey
LEFT JOIN 
    HighValueParts hp ON hp.p_partkey IN (
        SELECT ps.ps_partkey
        FROM partsupp ps
        JOIN RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
        WHERE rs.rnk = 1
    )
GROUP BY 
    r.r_regionkey, ns.n_name
HAVING 
    SUM(od.total_price) > (SELECT AVG(od2.total_price) FROM OrderDetails od2)
ORDER BY 
    region_name, total_orders DESC, grand_total_sales DESC;
