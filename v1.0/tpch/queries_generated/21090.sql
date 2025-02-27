WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_acctbal, 
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank,
        n.n_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        *
    FROM RankedSuppliers
    WHERE supplier_rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey, 
        SUM(ps.ps_availqty) AS total_availqty, 
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
OrderLineInfo AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1996-01-01'
    GROUP BY o.o_orderkey
)
SELECT 
    r.n_name AS Nation,
    COUNT(DISTINCT to.c_custkey) AS num_customers,
    SUM(to.total_spent) AS total_revenue,
    COUNT(DISTINCT ps.p_partkey) AS total_parts,
    AVG(COALESCE(pli.total_availqty, 0)) AS avg_availqty_per_part,
    STRING_AGG(DISTINCT ts.s_name, ', ') AS top_suppliers
FROM TopSuppliers ts
JOIN CustomerOrders to ON 1=1 -- Cross join for demonstration of bizarre semantics
LEFT JOIN PartSupplierInfo ps ON ps.num_suppliers > 5
LEFT JOIN nation r ON ts.n_name = r.n_name
LEFT JOIN OrderLineInfo oli ON oli.o_orderkey = to.o_custkey
WHERE r.r_regionkey IS NOT NULL
GROUP BY r.n_name
HAVING COUNT(to.c_custkey) > 10 AND SUM(to.total_spent IS NOT NULL) > 10000
ORDER BY total_revenue DESC
LIMIT 10 OFFSET 0;
