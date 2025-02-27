WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty, 
        ps.ps_supplycost,
        p.p_type,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, p.p_type
    HAVING 
        COUNT(DISTINCT l.l_orderkey) > 0
),
FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        psd.order_count,
        psd.ps_supplycost
    FROM 
        RankedSuppliers rs
    JOIN 
        PartSupplierDetails psd ON rs.s_suppkey = psd.ps_suppkey
    WHERE 
        rs.rank <= 3 AND psd.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT 
    c.c_name AS customer_name,
    c.c_acctbal AS customer_balance,
    fs.s_name AS supplier_name,
    fs.order_count,
    fs.ps_supplycost,
    COALESCE(ROUND(SUM(l.l_extendedprice * (1 - l.l_discount)), 2), 0) AS total_line_item_revenue
FROM 
    HighValueCustomers c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    FilteredSuppliers fs ON l.l_suppkey = fs.s_suppkey
WHERE 
    (l.l_returnflag = 'R' AND l.l_linestatus = 'O') OR (l.l_returnflag IS NULL AND l.l_linestatus = 'N')
GROUP BY 
    c.c_name, c.c_acctbal, fs.s_name, fs.order_count, fs.ps_supplycost
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_line_item_revenue DESC, fs.ps_supplycost ASC
LIMIT 10;
