WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_type
    HAVING 
        SUM(ps.ps_availqty) > 0
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.s_name,
    r.nation_name,
    p.p_name,
    p.total_avail_qty,
    od.total_sales,
    od.line_item_count
FROM 
    RankedSuppliers r
JOIN 
    FilteredParts p ON r.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey ORDER BY ps.ps_supplycost LIMIT 1)
JOIN 
    OrderDetails od ON od.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate = (SELECT MIN(o2.o_orderdate) FROM orders o2 WHERE o2.o_orderkey = od.o_orderkey) LIMIT 1)
WHERE 
    r.supplier_rank <= 5
ORDER BY 
    r.nation_name, total_sales DESC;
