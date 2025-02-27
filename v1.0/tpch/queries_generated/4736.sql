WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        DATE_PART('year', o.o_orderdate) AS order_year
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F') AND o.o_totalprice > 1000
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS line_total
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name AS nation_name, 
    COALESCE(SUM(fs.line_total), 0) AS total_line_items,
    COALESCE(MAX(rs.total_cost), 0) AS max_supplier_cost,
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    CASE 
        WHEN AVG(os.o_totalprice) > 5000 THEN 'High Value'
        ELSE 'Normal Value' 
    END AS order_value_category
FROM 
    nation n
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey AND rs.rn = 1
LEFT JOIN 
    FilteredLineItems fs ON fs.l_orderkey = (SELECT MIN(l_orderkey) FROM lineitem l WHERE l.l_orderkey = fs.l_orderkey)
LEFT JOIN 
    OrderSummary os ON os.o_orderkey = fs.l_orderkey
WHERE 
    n.n_regionkey IS NULL OR n.n_regionkey NOT IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
GROUP BY 
    n.n_name
ORDER BY 
    total_line_items DESC, max_supplier_cost ASC;
