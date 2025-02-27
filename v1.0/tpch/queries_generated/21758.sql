WITH RecursivePrice AS (
    SELECT 
        ps_partkey,
        SUM(ps_supplycost * ps_availqty) AS total_supplycost
    FROM 
        partsupp
    GROUP BY 
        ps_partkey
    HAVING 
        SUM(ps_supplycost * ps_availqty) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(*) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'O')
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
SupplierNation AS (
    SELECT 
        s.s_suppkey,
        n.n_name AS supplier_nation,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps_supplycost) DESC) AS nation_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, n.n_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 1
),
FilteredOrders AS (
    SELECT 
        h.o_orderkey,
        h.total_order_value,
        rn.supplier_nation
    FROM 
        HighValueOrders h
    JOIN 
        SupplierNation rn ON h.o_orderkey % 10 = rn.nation_rank
)
SELECT 
    p.p_name,
    COALESCE(fp.total_order_value, 0) AS order_value,
    rp.total_supplycost,
    (CASE 
        WHEN rp.total_supplycost IS NULL THEN 'No Supply Cost'
        WHEN COALESCE(fp.total_order_value, 0) > rp.total_supplycost THEN 'High Demand'
        ELSE 'Stable Supply'
    END) AS supply_status
FROM 
    part p
LEFT JOIN 
    RecursivePrice rp ON p.p_partkey = rp.ps_partkey
LEFT JOIN 
    FilteredOrders fp ON fp.supplier_nation LIKE '%' || SUBSTRING(p.p_name FROM 1 FOR 1) || '%'
WHERE 
    p.p_size BETWEEN 1 AND 30
    AND (p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) OR p.p_name IS NULL)
ORDER BY 
    p.p_name ASC, 
    supply_status DESC;
