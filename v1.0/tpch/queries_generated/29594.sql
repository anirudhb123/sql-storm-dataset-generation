WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_comment,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_comment
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        n.n_name AS nation_name,
        n.n_comment AS nation_comment,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_comment
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name AS customer_name,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, c.c_mktsegment
)
SELECT 
    pd.p_name,
    pd.p_brand,
    pd.total_available,
    sd.supplier_count,
    od.total_revenue,
    od.o_orderdate
FROM 
    PartDetails pd
JOIN 
    SupplierDetails sd ON pd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_name LIKE '%Supplier%'))
LEFT JOIN 
    OrderDetails od ON pd.p_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31')
WHERE 
    sd.supplied_parts > 0
ORDER BY 
    od.total_revenue DESC, 
    pd.p_name;
