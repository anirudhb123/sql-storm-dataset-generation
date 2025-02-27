WITH RECURSIVE RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TotalOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        COUNT(o.o_orderkey) OVER (PARTITION BY o.o_custkey) AS order_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(c.c_custkey) FILTER (WHERE c.c_acctbal > 0) AS positive_balance_count
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(c.c_custkey) > 10
)
SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    SUM(o.order_total) AS total_revenue,
    SUM(CASE WHEN s.rank = 1 THEN 1 ELSE 0 END) AS top_supplier_count,
    SUM(COALESCE(fn.positive_balance_count, 0)) AS total_positive_balances
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    TotalOrders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    RankedSuppliers s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    FilteredNations fn ON fn.n_nationkey = n.n_nationkey
WHERE 
    r.r_name LIKE 'S%'
GROUP BY 
    r.r_name
HAVING 
    SUM(o.order_total) > 100000
ORDER BY 
    total_revenue DESC NULLS LAST;
