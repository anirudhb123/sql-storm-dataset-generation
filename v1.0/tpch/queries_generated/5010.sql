WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        rs.nation_name
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighSpendingCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM 
        CustomerOrders co
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.nation_name,
    h.c_custkey,
    h.c_name,
    h.total_spent
FROM 
    TopSuppliers t
JOIN 
    HighSpendingCustomers h ON t.s_suppkey IN (
        SELECT ps.s_suppkey
        FROM partsupp ps
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_orderkey IN (
            SELECT o2.o_orderkey
            FROM orders o2
            JOIN customer c ON o2.o_custkey = c.c_custkey
            WHERE c.c_custkey = h.c_custkey
        )
        GROUP BY ps.s_suppkey
    )
WHERE 
    h.rank <= 10
ORDER BY 
    t.nation_name, h.total_spent DESC;
