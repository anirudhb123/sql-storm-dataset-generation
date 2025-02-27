
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY s.s_acctbal DESC) AS supplier_rank,
        p.p_partkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        ns.n_name,
        COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
        SUM(rs.s_acctbal) AS total_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey)
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.supplier_rank <= 3
    GROUP BY 
        r.r_name, ns.n_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        o.o_orderdate,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            ELSE 'Pending'
        END AS order_status,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
)
SELECT 
    td.o_orderkey,
    td.o_totalprice,
    td.net_revenue,
    td.order_status,
    ts.r_name,
    ts.n_name,
    ts.supplier_count,
    ts.total_acctbal
FROM 
    OrderDetails td
LEFT JOIN 
    TopSuppliers ts ON td.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN 
    (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal > 1000))
WHERE 
    td.order_rank <= 10
ORDER BY 
    td.o_orderdate DESC, ts.total_acctbal DESC;
