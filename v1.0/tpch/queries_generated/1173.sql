WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1)
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        su.s_name,
        su.s_acctbal
    FROM 
        RankedSuppliers su
    LEFT JOIN 
        region r ON su.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_regionkey = r.r_regionkey)
    WHERE 
        su.supplier_rank <= 3
),
TotalOrders AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_custkey
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(tp.total_spent, 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        TotalOrders tp ON c.c_custkey = tp.o_custkey
)
SELECT 
    cu.c_custkey,
    cu.c_name,
    cu.total_spent,
    ts.r_name AS supplier_region
FROM 
    CustomerPurchases cu
JOIN 
    TopSuppliers ts ON cu.total_spent > (SELECT AVG(total_spent) FROM CustomerPurchases)
WHERE 
    cu.total_spent IS NOT NULL
ORDER BY 
    cu.total_spent DESC, 
    ts.r_name;
