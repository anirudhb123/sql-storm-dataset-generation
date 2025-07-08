
WITH RegionalSales AS (
    SELECT
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
),
DiscountedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name 
    ORDER BY 
        supplier_value DESC
    LIMIT 10
)
SELECT 
    r.nation_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    t.s_name AS top_supplier,
    t.total_parts,
    t.supplier_value
FROM 
    (SELECT n.n_name AS nation_name FROM nation n) r
LEFT JOIN 
    RegionalSales rs ON r.nation_name = rs.nation_name
LEFT JOIN 
    TopSuppliers t ON EXISTS (
        SELECT 1
        FROM supplier s 
        WHERE s.s_name = t.s_name AND s.s_nationkey = (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_name = r.nation_name
        )
    )
WHERE 
    r.nation_name IS NOT NULL
ORDER BY 
    total_sales DESC, top_supplier;
