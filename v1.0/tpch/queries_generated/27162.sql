WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s_acctbal) 
            FROM supplier
        )
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_name
    FROM 
        RankedSuppliers s
    WHERE 
        s.rn <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    cs.c_name AS customer_name,
    fs.s_name AS supplier_name,
    fs.s_acctbal AS supplier_balance,
    co.total_spent AS total_customer_spent
FROM 
    FilteredSuppliers fs
JOIN 
    CustomerOrders co ON co.o_orderkey IN (SELECT l_orderkey FROM lineitem WHERE l_partkey IN (SELECT p_partkey FROM part WHERE p_name = fs.p_name))
JOIN 
    customer cs ON cs.c_custkey = co.c_custkey
ORDER BY 
    fs.s_acctbal DESC, co.total_spent DESC;
