WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate <= DATE '2023-12-31'
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
high_value_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        p.p_retailprice > 100
        AND l.l_shipdate IS NOT NULL
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        total_revenue > (SELECT AVG(total_revenue) FROM (
            SELECT 
                SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
            FROM 
                lineitem 
            GROUP BY 
                l_partkey
        ) AS avg_revenue)
),
nation_performance AS (
    SELECT 
        n.n_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS total_customers
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name,
    COALESCE(n.total_sales, 0) AS total_sales,
    COALESCE(s.distinct_parts, 0) AS distinct_parts,
    COALESCE(h.total_revenue, 0) AS high_value_revenue
FROM 
    region r
LEFT JOIN 
    nation_performance n ON n.n_nationkey = r.r_regionkey
LEFT JOIN 
    supplier_summary s ON s.s_suppkey = (SELECT ps.s_suppkey FROM partsupp ps ORDER BY ps.ps_availqty DESC LIMIT 1)
LEFT JOIN 
    (SELECT p.p_partkey, p.p_name, p.p_retailprice, h.total_revenue
     FROM high_value_parts h
     JOIN part p ON h.p_partkey = p.p_partkey
     WHERE p.p_name LIKE '%Gadget%') AS h ON h.p_partkey IS NOT NULL
WHERE 
    r.r_name LIKE 'A%'
ORDER BY 
    total_sales DESC,
    distinct_parts ASC
LIMIT 10;
