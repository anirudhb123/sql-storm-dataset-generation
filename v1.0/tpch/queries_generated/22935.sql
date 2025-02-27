WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000.00
), 
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) > 0
), 
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice) AS total_price,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count,
        AVG(l.l_discount) AS avg_discount
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
), 
CombinedStats AS (
    SELECT 
        ps.p_partkey,
        ps.p_name,
        os.total_price,
        os.lineitem_count,
        os.avg_discount,
        rs.s_name AS supplier_name,
        rs.s_acctbal,
        COALESCE(os.avg_discount / NULLIF(rs.s_acctbal, 0), 0) AS discount_to_acctbal_ratio
    FROM 
        PartStats ps
    LEFT JOIN 
        RankedSuppliers rs ON ps.p_partkey = rs.s_suppkey 
    LEFT JOIN 
        OrderStats os ON os.lineitem_count > 0
)

SELECT 
    c.c_custkey,
    c.c_name,
    cs.p_partkey,
    cs.p_name,
    cs.total_available,
    cs.total_price,
    CASE 
        WHEN cs.discount_to_acctbal_ratio IS NULL THEN 'No discount'
        WHEN cs.discount_to_acctbal_ratio > 0.1 THEN 'High discount'
        ELSE 'Low discount'
    END AS discount_category
FROM 
    customer c
LEFT JOIN 
    CombinedStats cs ON c.c_custkey = cs.p_partkey
WHERE 
    (c.c_acctbal IS NOT NULL AND c.c_acctbal < 500.00) 
    OR (cs.total_available IS NULL AND c.c_name LIKE 'A%')
ORDER BY 
    cs.discount_category DESC, c.c_custkey
FETCH FIRST 100 ROWS ONLY
