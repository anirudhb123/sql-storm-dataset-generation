WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus <> 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    sc.total_cost,
    od.total_order_value,
    od.order_rank
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierCosts sc ON s.s_suppkey = sc.s_suppkey
LEFT JOIN 
    OrderDetails od ON sc.part_count > 0
WHERE 
    (sc.total_cost IS NOT NULL AND sc.total_cost > 10000) OR 
    (od.total_order_value IS NOT NULL AND od.total_order_value > 5000)
ORDER BY 
    region_name, nation_name, supplier_name;
