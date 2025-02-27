WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
FrequentCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
), 
TopParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    r.nation_name, 
    rs.s_name, 
    rs.s_acctbal, 
    fc.c_name, 
    fc.order_count, 
    tp.p_name, 
    tp.total_sales
FROM 
    RankedSuppliers rs
JOIN 
    FrequentCustomers fc ON 1=1
JOIN 
    TopParts tp ON 1=1
JOIN 
    nation r ON rs.nation_name = r.n_name
WHERE 
    rs.rank <= 3 AND 
    (rs.s_acctbal > 10000 OR fc.order_count > 10)
ORDER BY 
    r.nation_name, rs.s_acctbal DESC, fc.order_count DESC, tp.total_sales DESC;
