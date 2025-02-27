WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        cus.c_custkey,
        cus.c_name,
        cus.total_spent,
        ROW_NUMBER() OVER (ORDER BY cus.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrderSummary cus
)
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(COALESCE(li.l_extendedprice * (1 - li.l_discount), 0)) AS total_revenue,
    ns.n_name,
    rc.total_spent AS customer_total_spent
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem li ON ps.ps_suppkey = li.l_suppkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN 
    TopCustomers rc ON li.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = rc.c_custkey)
WHERE 
    p.p_size > 10 AND 
    (li.l_returnflag = 'N' OR li.l_returnflag IS NULL)
GROUP BY 
    p.p_name, ns.n_name, rc.total_spent
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 1 AND 
    SUM(li.l_quantity) > 100
ORDER BY 
    total_revenue DESC, supplier_count ASC;
