WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_partkey
    FROM 
        RankedSuppliers s
    JOIN 
        part p ON s.ps_partkey = p.p_partkey
    WHERE 
        s.rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    ps.p_partkey,
    ps.ps_supplycost,
    ts.s_name AS top_supplier_name,
    co.cust_key,
    co.total_spent,
    co.order_count,
    co.last_order_date
FROM 
    partsupp ps
JOIN 
    TopSuppliers ts ON ps.ps_partkey = ts.p_partkey
JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT MIN(c.c_custkey) FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'GERMANY'))
WHERE 
    ps.ps_availqty > 0
ORDER BY 
    total_spent DESC, ps.ps_supplycost ASC
LIMIT 50;
