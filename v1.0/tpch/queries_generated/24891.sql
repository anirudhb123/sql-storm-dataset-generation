WITH CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_mktsegment = 'BUILDING')
    GROUP BY 
        c.c_custkey, c.c_name
),
RecentOrders AS (
    SELECT 
        co.c_custkey,
        co.total_spent,
        ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY co.last_order_date DESC) AS order_rank
    FROM 
        CustomerOrders co
    WHERE 
        co.order_count > 0
),
TopSpenders AS (
    SELECT 
        r.*, 
        nt.n_name,
        DENSE_RANK() OVER (ORDER BY r.total_spent DESC) AS spender_rank
    FROM 
        RecentOrders r
    JOIN 
        customer c ON r.c_custkey = c.c_custkey
    JOIN 
        nation nt ON c.c_nationkey = nt.n_nationkey
    WHERE 
        r.total_spent > (SELECT MAX(total_spent) FROM CustomerOrders) * 0.5
)
SELECT 
    ts.spender_rank,
    ts.c_custkey,
    ts.total_spent,
    ts.n_name,
    (
        SELECT 
            COUNT(DISTINCT ps.ps_partkey)
        FROM 
            partsupp ps
        JOIN 
            lineitem l ON ps.ps_suppkey = l.l_suppkey
        WHERE 
            l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = ts.c_custkey)
            AND ps.ps_availqty IS NOT NULL 
    ) AS distinct_parts_count,
    (
        SELECT 
            COUNT(*)
        FROM 
            lineitem l2
        WHERE 
            l2.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = ts.c_custkey)
            AND l2.l_discount > 0
    ) AS discounts_applied
FROM 
    TopSpenders ts
WHERE 
    ts.spender_rank <= 10
ORDER BY 
    ts.total_spent DESC
LIMIT 5;
