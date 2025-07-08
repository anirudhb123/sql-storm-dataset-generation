
WITH RECURSIVE order_totals AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
nation_summary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
filtered_orders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice) AS total_order_value,
        n.n_name
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, n.n_name
),
ranked_orders AS (
    SELECT 
        fo.o_orderkey,
        fo.total_order_value,
        fo.n_name,
        RANK() OVER (PARTITION BY fo.n_name ORDER BY fo.total_order_value DESC) AS order_rank
    FROM 
        filtered_orders fo
)

SELECT 
    ns.n_name,
    ns.supplier_count,
    ns.total_account_balance,
    ro.total_order_value,
    ro.order_rank
FROM 
    nation_summary ns
LEFT JOIN 
    ranked_orders ro ON ns.n_name = ro.n_name
WHERE 
    ns.total_account_balance IS NOT NULL
ORDER BY 
    ns.supplier_count DESC, ro.total_order_value DESC
LIMIT 10;
