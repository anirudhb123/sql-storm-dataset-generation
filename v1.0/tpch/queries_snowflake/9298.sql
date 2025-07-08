WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 50000
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
TopOrderDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.s_name AS supplier_name,
    r.total_supply_cost AS supplier_total_cost,
    c.c_name AS customer_name,
    c.c_acctbal AS customer_account_balance,
    o.l_orderkey AS order_key,
    o.total_line_value AS order_total_value,
    o.distinct_parts_count AS parts_count
FROM 
    RankedSuppliers r
JOIN 
    HighValueCustomers c ON r.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_custkey = c.c_custkey))
JOIN 
    TopOrderDetails o ON o.l_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = r.s_suppkey)
WHERE 
    r.supplier_rank <= 10
ORDER BY 
    r.total_supply_cost DESC, c.c_acctbal DESC;
