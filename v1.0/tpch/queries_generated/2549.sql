WITH NationSummary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
)

SELECT 
    o.o_orderkey,
    c.c_name,
    c.c_acctbal,
    o.total_spent,
    ns.n_name,
    ns.supplier_count,
    CASE 
        WHEN o.total_spent > 1000 THEN 'High'
        WHEN o.total_spent BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS spending_category,
    COALESCE(l.l_discount, 0) AS discount,
    ROW_NUMBER() OVER (PARTITION BY ns.n_name ORDER BY o.total_spent DESC) AS spent_rank
FROM 
    OrderSummary o
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    NationSummary ns ON c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = ns.n_name)
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    o.rank <= 10 
    AND (c.c_acctbal IS NOT NULL OR c.c_acctbal > 0)
ORDER BY 
    ns.n_name, o.total_spent DESC;
