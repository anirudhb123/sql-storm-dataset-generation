WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        n.n_name AS nation_name,
        n.n_regionkey,
        COUNT(DISTINCT ps.ps_partkey) AS available_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name, n.n_regionkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
PartRevenue AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
    FROM 
        part p
    JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)

SELECT 
    rd.nation_name, 
    rd.available_parts,
    COALESCE(pr.p_name, 'N/A') AS part_name,
    COALESCE(pr.revenue, 0) AS total_revenue,
    CASE 
        WHEN pr.revenue IS NOT NULL THEN 'Part Sold'
        ELSE 'No Sales'
    END AS sales_status,
    COUNT(od.o_orderkey) AS order_count,
    AVG(od.total_revenue) AS avg_order_revenue
FROM 
    SupplierDetails rd
LEFT JOIN 
    PartRevenue pr ON rd.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = pr.p_partkey LIMIT 1)
LEFT JOIN 
    OrderDetails od ON od.o_orderdate >= '1997-01-01' AND od.o_orderdate < '1997-12-31'
GROUP BY 
    rd.nation_name, rd.available_parts, pr.p_name, pr.revenue
ORDER BY 
    rd.nation_name, available_parts DESC, total_revenue DESC;