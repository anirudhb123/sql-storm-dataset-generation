WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    n.n_name AS nation_name,
    rs.total_supply_cost,
    od.total_value,
    CASE 
        WHEN rs.parts_supplied > 5 THEN 'High'
        WHEN rs.parts_supplied BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS supplier_rating,
    COALESCE(od.total_value, 0) AS order_total
FROM 
    nation n
LEFT JOIN 
    SupplierSummary rs ON n.n_nationkey = (SELECT DISTINCT s.s_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey)
LEFT JOIN 
    OrderDetails od ON od.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O' LIMIT 1 OFFSET 0)
WHERE 
    rs.total_supply_cost IS NOT NULL
ORDER BY 
    n.n_name, rs.total_supply_cost DESC, od.total_value DESC;
