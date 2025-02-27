WITH TotalSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        t.c_custkey,
        t.c_name,
        t.total_spent,
        RANK() OVER (ORDER BY t.total_spent DESC) AS rank
    FROM 
        TotalSales t
)
SELECT 
    rc.r_name AS region_name,
    nc.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT tc.c_custkey) AS num_customers,
    SUM(tc.total_spent) AS total_revenue
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.c_custkey = c.c_custkey
JOIN 
    nation nc ON c.c_nationkey = nc.n_nationkey
JOIN 
    region rc ON nc.n_regionkey = rc.r_regionkey
JOIN 
    partsupp ps ON ps.ps_partkey IN (
        SELECT ps_partkey 
        FROM lineitem 
        WHERE l_orderkey IN (
            SELECT o.o_orderkey 
            FROM orders o
            WHERE o.o_custkey = c.c_custkey
        )
    )
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    tc.rank <= 10
GROUP BY 
    rc.r_name, nc.n_name, s.s_name
ORDER BY 
    total_revenue DESC;
