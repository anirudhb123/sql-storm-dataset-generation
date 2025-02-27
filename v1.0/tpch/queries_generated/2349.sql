WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS acct_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 5000
),
high_order_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value,
        COUNT(l.l_number) AS number_of_items
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    lo.total_lineitem_value,
    lo.number_of_items,
    COALESCE(d.acct_rank, 0) AS supplier_acct_rank,
    COALESCE(r.price_rank, 0) AS part_price_rank
FROM 
    ranked_parts r
LEFT JOIN 
    partsupp ps ON r.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier_details d ON ps.ps_suppkey = d.s_suppkey
JOIN 
    lineitem_summary lo ON ps.ps_partkey = lo.l_orderkey
JOIN 
    high_order_customers c ON c.c_custkey = o.o_custkey
JOIN 
    orders o ON o.o_orderkey = lo.l_orderkey
WHERE 
    r.price_rank <= 5 
    AND d.acct_rank < 3
    AND lo.total_lineitem_value IS NOT NULL
ORDER BY 
    r.p_retailprice DESC, 
    total_lineitem_value DESC;
