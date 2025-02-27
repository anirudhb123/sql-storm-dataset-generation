WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name, 
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
), OrderInfo AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        total_revenue > 10000
), TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(oi.total_revenue) AS total_spent
    FROM 
        customer c
    JOIN 
        OrderInfo oi ON c.c_custkey = oi.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
)
SELECT 
    sd.s_name, 
    sd.nation_name, 
    sd.region_name, 
    tc.total_spent
FROM 
    SupplierDetails sd
JOIN 
    TopCustomers tc ON sd.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            JOIN orders o ON l.l_orderkey = o.o_orderkey 
            WHERE o.o_custkey = tc.c_custkey
        )
    )
ORDER BY 
    tc.total_spent DESC;
