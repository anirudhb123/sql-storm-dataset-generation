WITH ProcessedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        LOWER(p.p_name) AS lower_name,
        CONCAT(p.p_brand, '-', p.p_type) AS brand_type
    FROM 
        part p
),
SupplierNation AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        CASE 
            WHEN s.s_acctbal < 1000 THEN 'Low'
            WHEN s.s_acctbal BETWEEN 1000 AND 10000 THEN 'Medium'
            ELSE 'High'
        END AS account_balance_category
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name, o.o_orderdate
)
SELECT 
    pp.lower_name,
    pp.brand_type,
    sn.nation_name,
    od.total_revenue,
    od.unique_parts,
    RANK() OVER (PARTITION BY sn.account_balance_category ORDER BY od.total_revenue DESC) AS revenue_rank
FROM 
    ProcessedParts pp
JOIN 
    SupplierNation sn ON pp.p_partkey % 10 = sn.s_suppkey % 10
JOIN 
    OrderDetails od ON pp.p_partkey % 5 = od.o_orderkey % 5
WHERE 
    pp.name_length > 30
ORDER BY 
    sn.account_balance_category, od.total_revenue DESC;
