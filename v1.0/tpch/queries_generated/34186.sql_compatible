
WITH RECURSIVE OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate

    UNION ALL

    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        OrderSummary os ON os.o_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), TotalOrders AS (
    SELECT 
        os.o_orderkey,
        os.o_orderdate,
        os.total_revenue,
        os.total_items,
        RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM 
        OrderSummary os
)

SELECT 
    p.p_partkey,
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE 
        WHEN l.l_discount > 0 THEN l.l_discount * l.l_extendedprice 
        ELSE 0 
    END) AS total_discounted_value,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
    MAX(COALESCE(c.c_acctbal, 0)) AS max_customer_account_balance
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    EXISTS (SELECT 1 FROM nation n WHERE n.n_nationkey = c.c_nationkey AND n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA'))
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    net_sales DESC;
