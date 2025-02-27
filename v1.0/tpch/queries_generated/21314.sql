WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rn
    FROM 
        supplier s
), 
OrderStats AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS num_items,
        MAX(o.o_totalprice) AS max_order_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
CustomerStats AS (
    SELECT 
        c.c_custkey, 
        MAX(o.o_orderdate) AS last_order_date,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)

SELECT 
    n.n_name,
    r.r_name,
    COALESCE(SUM(os.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT cs.c_custkey) AS num_customers,
    MAX(cs.total_spent) AS highest_spent_customer,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedSuppliers s ON n.n_nationkey = s.s_nationkey AND s.rn <= 5 
LEFT JOIN 
    OrderStats os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
LEFT JOIN 
    CustomerStats cs ON cs.last_order_date BETWEEN DATEADD(MONTH, -1, CURRENT_DATE) AND CURRENT_DATE
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    n.n_name, r.r_name
HAVING 
    SUM(os.total_revenue) IS NOT NULL 
    OR COUNT(s.s_suppkey) > 0 
ORDER BY 
    total_revenue DESC, highest_spent_customer ASC;
