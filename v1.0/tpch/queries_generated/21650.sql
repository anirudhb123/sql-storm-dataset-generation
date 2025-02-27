WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rnk,
        COUNT(ps.ps_availqty) OVER (PARTITION BY s.s_suppkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
SupplierStats AS (
    SELECT 
        rs.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        RankedSuppliers rs
    JOIN 
        lineitem l ON rs.s_suppkey = l.l_suppkey
    GROUP BY 
        rs.s_suppkey
)
SELECT 
    n.n_name,
    COALESCE(ss.total_revenue, 0) AS supplier_revenue,
    CASE 
        WHEN hs.o_orderkey IS NOT NULL THEN 'High Value Order'
        ELSE 'Regular Order'
    END AS order_classification,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count
FROM 
    nation n
LEFT JOIN 
    SupplierStats ss ON n.n_nationkey = (SELECT DISTINCT c.c_nationkey 
                                           FROM customer c 
                                           WHERE c.c_custkey IN (SELECT DISTINCT o.o_custkey 
                                                                 FROM HighValueOrders hs 
                                                                 WHERE hs.o_orderdate = 
                                                                        (SELECT MAX(o_orderdate) 
                                                                         FROM HighValueOrders)))
    LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = ss.s_suppkey
    LEFT JOIN 
    HighValueOrders hs ON hs.o_orderkey = (SELECT MAX(o.o_orderkey) 
                                             FROM orders o 
                                             WHERE o.o_orderstatus = 'O')
GROUP BY
    n.n_name, ss.total_revenue, hs.o_orderkey
ORDER BY 
    supplier_revenue DESC, n.n_name;
