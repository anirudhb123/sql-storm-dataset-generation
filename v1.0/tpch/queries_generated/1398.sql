WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
), 
TopSuppliers AS (
    SELECT 
        r.r_name,
        rs.s_name,
        rs.s_acctbal
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
    WHERE 
        rs.supplier_rank <= 3
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2023-10-01'
)

SELECT 
    cs.c_custkey,
    cs.c_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_spent,
    ts.r_name AS supplier_region
FROM 
    CustomerOrders cs
LEFT JOIN 
    lineitem l ON cs.o_orderkey = l.l_orderkey
LEFT JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
GROUP BY 
    cs.c_custkey, cs.c_name, ts.r_name
HAVING 
    total_spent > (SELECT AVG(total_spent)
                   FROM (
                       SELECT 
                           c.c_custkey,
                           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
                       FROM 
                           customer c
                       JOIN 
                           orders o ON c.c_custkey = o.o_custkey
                       JOIN 
                           lineitem l ON o.o_orderkey = l.l_orderkey
                       WHERE 
                           o.o_orderdate >= DATE '2023-01-01' 
                           AND o.o_orderdate < DATE '2023-10-01'
                       GROUP BY 
                           c.c_custkey
                   ) AS avg_spend) 
ORDER BY 
    total_spent DESC;
