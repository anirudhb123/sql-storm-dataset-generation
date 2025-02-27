WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        DENSE_RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 0
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey,
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
), 
SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS sup_count,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.o_orderkey,
    co.o_orderdate,
    COALESCE(SI.sup_count, 0) AS supplier_count,
    SI.avg_supplycost,
    SUM(RS.s_acctbal) AS top_supplier_balance
FROM 
    CustomerOrders co
LEFT JOIN 
    SupplierInfo SI ON SI.ps_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = co.o_orderkey
    ) 
LEFT JOIN 
    RankedSuppliers RS ON RS.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey = co.o_orderkey
        ) 
        AND RS.supplier_rank = 1
    )
WHERE 
    co.total_spent > 1000.00
GROUP BY 
    co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, SI.sup_count, SI.avg_supplycost
ORDER BY 
    co.o_orderdate DESC, co.total_spent DESC;
