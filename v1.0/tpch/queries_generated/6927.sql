WITH supplier_part_info AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        ps.ps_partkey, 
        p.p_name, 
        p.p_brand, 
        ps.ps_supplycost, 
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), nation_revenue AS (
    SELECT 
        n.n_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        customer c ON s.s_suppkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    n.r_name AS region_name, 
    n.n_name AS nation_name, 
    SUM(nr.total_revenue) AS total_nation_revenue,
    COUNT(DISTINCT spi.s_suppkey) AS distinct_suppliers,
    COUNT(DISTINCT spi.ps_partkey) AS distinct_parts,
    AVG(spi.ps_supplycost) AS average_supply_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    nation_revenue nr ON n.n_nationkey = nr.n_nationkey
LEFT JOIN 
    supplier_part_info spi ON spi.s_nationkey = n.n_nationkey AND spi.rank <= 5
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_nation_revenue DESC, r.r_name ASC;
