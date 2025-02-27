WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
TopNations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        n.n_name IS NOT NULL
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_linenumber) AS line_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    co.c_custkey,
    co.order_count,
    co.total_spent,
    tn.n_name AS nation_name,
    rs.s_name AS top_supplier,
    od.revenue,
    od.line_count
FROM 
    CustomerOrders co
LEFT JOIN 
    TopNations tn ON co.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = tn.n_nationkey)
LEFT JOIN 
    RankedSuppliers rs ON rs.rn = 1
LEFT JOIN 
    OrderDetails od ON od.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
WHERE 
    co.total_spent > 5000
ORDER BY 
    co.total_spent DESC, co.order_count ASC;
