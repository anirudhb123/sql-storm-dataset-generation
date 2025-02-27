WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        COALESCE(SUM(od.total_value), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
ProductSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey 
),
HighValueCustomers AS (
    SELECT 
        cus.c_custkey,
        cus.c_name,
        cus.total_spent
    FROM 
        CustomerOrderSummary cus
    WHERE 
        cus.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderSummary)
),
TopProducts AS (
    SELECT 
        ps.p_partkey,
        ps.p_name,
        ps.ps_supplycost
    FROM 
        ProductSupplier ps
    WHERE 
        ps.supplier_rank = 1
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    rv.c_custkey,
    rv.c_name,
    rv.total_spent,
    tp.p_name AS top_product,
    SUM(tp.ps_supplycost) AS total_supply_cost
FROM 
    HighValueCustomers rv
JOIN 
    customer c ON rv.c_custkey = c.c_custkey
JOIN 
    nation ns ON c.c_nationkey = ns.n_nationkey
JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
JOIN 
    TopProducts tp ON tp.p_partkey IN (
        SELECT DISTINCT l.l_partkey
        FROM lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_custkey = rv.c_custkey
    )
GROUP BY 
    r.r_name, ns.n_name, rv.c_custkey, rv.c_name, tp.p_name
HAVING 
    COUNT(DISTINCT tp.p_name) > 2
ORDER BY 
    total_supply_cost DESC, region_name, nation_name;
