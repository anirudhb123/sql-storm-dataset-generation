WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
PopularParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT l.l_orderkey) DESC) AS popular_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
AggregatedInfo AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROUND(AVG(p.p_retailprice), 2) AS avg_part_price
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        part p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
    GROUP BY 
        r.r_name
)

SELECT 
    a.r_name,
    a.nation_count,
    a.supplier_count,
    a.customer_count,
    a.order_count,
    a.avg_part_price,
    rc.c_name AS top_customer_name,
    pp.p_name AS top_part_name
FROM 
    AggregatedInfo a
LEFT JOIN 
    RankedCustomers rc ON rc.rank = 1
LEFT JOIN 
    PopularParts pp ON pp.popular_rank = 1
ORDER BY 
    a.r_name;
