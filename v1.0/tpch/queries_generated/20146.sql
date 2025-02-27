WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
), 
PartSupplies AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
Sales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales_volume,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.sales_volume, 0) AS total_sales,
    COALESCE(pt.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN COALESCE(s.sales_volume, 0) > COALESCE(pt.total_supply_cost, 0) THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability,
    r.r_name AS supplier_region
FROM 
    part p
LEFT JOIN 
    Sales s ON p.p_partkey = s.l_partkey
LEFT JOIN 
    PartSupplies pt ON p.p_partkey = pt.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON rs.rank = 1
LEFT JOIN 
    nation n ON n.n_nationkey = rs.s_nationkey
LEFT JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    p.p_size BETWEEN 10 AND 20 
    AND p.p_comment LIKE '%fragile%'
    AND (n.n_comment IS NULL OR n.n_comment <> '')
ORDER BY 
    total_sales DESC, p.p_name
FETCH FIRST 100 ROWS ONLY;
