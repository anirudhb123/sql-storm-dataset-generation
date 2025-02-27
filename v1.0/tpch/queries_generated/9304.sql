WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.nation_name,
        rs.total_supply_cost
    FROM RankedSuppliers rs
    WHERE rs.rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    fs.s_name AS supplier_name,
    fs.nation_name,
    co.c_name AS customer_name,
    co.total_order_value,
    co.order_count
FROM FilteredSuppliers fs
JOIN CustomerOrders co ON fs.s_suppkey = 
    (SELECT ps.ps_suppkey
     FROM partsupp ps
     JOIN lineitem l ON ps.ps_partkey = l.l_partkey
     WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
     GROUP BY ps.ps_suppkey
     ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC
     LIMIT 1)
ORDER BY fs.total_supply_cost DESC, co.total_order_value DESC;
