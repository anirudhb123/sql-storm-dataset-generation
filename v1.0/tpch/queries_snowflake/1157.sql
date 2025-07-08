WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name, 
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000
), TotalOrders AS (
    SELECT 
        o.o_custkey, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-10-31'
    GROUP BY 
        o.o_custkey
), SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ps.ps_partkey,
    COALESCE(ps.total_available, 0) AS total_available,
    COALESCE(ts.total_spent, 0) AS total_spent,
    COALESCE(ls.total_line_revenue, 0) AS total_line_revenue
FROM 
    SupplierParts ps
LEFT JOIN 
    TotalOrders ts ON ts.o_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = (
            SELECT n.n_nationkey 
            FROM nation n 
            JOIN RankedSuppliers rs ON rs.nation_name = n.n_name
            WHERE rs.rn = 1)
    )
LEFT JOIN 
    LineItemSummary ls ON ls.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey IN (
            SELECT c.c_custkey 
            FROM customer c 
            WHERE c.c_nationkey = (
                SELECT n.n_nationkey 
                FROM nation n 
                WHERE n.n_name IS NOT NULL)
        )
    )
WHERE 
    ps.total_available > 0 
ORDER BY 
    ps.ps_partkey;