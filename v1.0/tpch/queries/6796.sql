WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_custkey, c.c_name, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_name,
        SUM(ro.total_revenue) AS total_spent,
        RANK() OVER (ORDER BY SUM(ro.total_revenue) DESC) AS rank
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.c_custkey = c.c_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    tc.c_name,
    tc.total_spent,
    r.r_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM 
    TopCustomers tc
JOIN 
    orders o ON tc.c_name = (SELECT c.c_name FROM customer c WHERE c.c_custkey = o.o_custkey)
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    tc.rank <= 10
GROUP BY 
    tc.c_name, tc.total_spent, r.r_name
ORDER BY 
    tc.total_spent DESC, supplier_count DESC;
