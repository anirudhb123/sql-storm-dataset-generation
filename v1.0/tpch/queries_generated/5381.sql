WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        r.r_comment,
        COUNT(rs.s_suppkey) AS supplier_count,
        SUM(rs.s_acctbal) AS total_acctbal
    FROM 
        region r
    JOIN 
        RankedSuppliers rs ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = rs.s_suppkey)
    WHERE 
        rs.rank <= 5
    GROUP BY 
        r.r_name, r.r_comment
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ts.r_name,
    ts.supplier_count,
    ts.total_acctbal,
    od.o_orderkey,
    od.revenue
FROM 
    TopSuppliers ts
JOIN 
    OrderDetails od ON ts.supplier_count > 10
ORDER BY 
    ts.total_acctbal DESC, od.revenue DESC;
