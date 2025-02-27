WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        SUBSTRING(s.s_comment FROM 1 FOR 20) AS short_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        CONCAT('Retail Price: ', CAST(p.p_retailprice AS VARCHAR), ' | Comment: ', p.p_comment) AS detailed_comment
    FROM 
        part p
    WHERE 
        p.p_size IN (10, 20, 30)
),
OrderAnalysis AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS line_item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    sd.s_name,
    sd.nation_name,
    pd.p_name,
    pd.p_type,
    od.o_orderkey,
    od.o_orderdate,
    od.line_item_count,
    od.total_revenue,
    pd.detailed_comment
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    OrderAnalysis od ON ps.ps_partkey = od.o_orderkey
WHERE 
    sd.s_acctbal > 10000 AND od.revenue_rank = 1
ORDER BY 
    sd.nation_name, pd.p_name, od.total_revenue DESC
LIMIT 100;
