WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER(PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
ActiveCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER(ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 0
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year,
        SUM(l.l_quantity * (1 - l.l_discount)) AS total_lineitem_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, order_year
)
SELECT 
    ns.n_name,
    COUNT(DISTINCT ac.c_custkey) AS active_customer_count,
    SUM(os.total_lineitem_value) AS total_revenue,
    COALESCE(MIN(rs.rank), 0) AS min_supplier_rank
FROM 
    nation ns
LEFT JOIN 
    ActiveCustomers ac ON ac.c_nationkey = ns.n_nationkey
LEFT JOIN 
    OrderSummary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = ac.c_custkey)
LEFT JOIN 
    RankedSuppliers rs ON rs.s_nationkey = ns.n_nationkey
WHERE 
    ns.r_name LIKE 'N%'
GROUP BY 
    ns.n_name
ORDER BY 
    total_revenue DESC, active_customer_count DESC
LIMIT 10;
