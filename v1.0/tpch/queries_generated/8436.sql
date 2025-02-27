WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE
            WHEN c.c_acctbal > 10000 THEN 'High'
            WHEN c.c_acctbal BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS cust_value
    FROM customer c
)
SELECT 
    r.r_name AS region,
    ns.n_name AS nation,
    rs.s_name AS supplier_name,
    rsc.total_cost AS supplier_cost,
    hvc.c_name AS customer_name,
    hvc.c_acctbal AS customer_balance,
    hvc.cust_value AS customer_category
FROM RankedSuppliers rsc
JOIN nation ns ON rsc.n_name = ns.n_name
JOIN region r ON ns.n_regionkey = r.r_regionkey
JOIN HighValueCustomers hvc ON hvc.c_custkey IN (
    SELECT o.o_custkey
    FROM orders o
    WHERE o.o_orderkey IN (
        SELECT l.l_orderkey
        FROM lineitem l
        WHERE l.l_partkey IN (
            SELECT p.p_partkey
            FROM part p
            WHERE p.p_brand = 'Brand#24'
        )
    )
)
JOIN supplier rs ON rs.s_suppkey = rsc.s_suppkey
WHERE rsc.rank <= 10
ORDER BY r.r_name, ns.n_name, rsc.total_cost DESC, hvc.c_acctbal DESC;
