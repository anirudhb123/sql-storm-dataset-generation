WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
), CustomerOrderCounts AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
)

SELECT 
    h.c_custkey, 
    h.c_name, 
    h.c_acctbal, 
    COALESCE(o.order_count, 0) AS order_count,
    r.s_name AS top_supplier,
    r.total_supply_cost
FROM 
    HighValueCustomers h
LEFT JOIN 
    CustomerOrderCounts o ON h.c_custkey = o.c_custkey
LEFT JOIN 
    (SELECT 
        s.n_nationkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        RankedSuppliers r
    JOIN 
        nation s ON r.s_suppkey = s.n_nationkey 
    WHERE 
        r.supplier_rank = 1
    GROUP BY 
        s.n_nationkey, s.s_name) r ON r.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey IS NOT NULL LIMIT 1)
ORDER BY 
    h.c_acctbal DESC, order_count DESC;
