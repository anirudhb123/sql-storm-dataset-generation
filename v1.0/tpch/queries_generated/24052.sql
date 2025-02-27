WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        DENSE_RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) as balance_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
MaxBalance AS (
    SELECT 
        ps_partkey,
        MAX(s_acctbal) as max_balance
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        ps_partkey
),
OrdersSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'O')
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
RegionFilter AS (
    SELECT 
        n.n_nationkey, 
        r.r_regionkey
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name NOT LIKE '%west%' 
        AND n.n_comment IS NOT NULL
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(sb.total_revenue, 0) AS total_revenue,
    rs.s_name AS top_supplier_name,
    rb.max_balance, 
    ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY p.p_partkey DESC) as part_rank
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    (SELECT 
         ps_partkey, 
         SUM(total_revenue) AS total_revenue
     FROM 
         OrdersSummary 
     WHERE 
         o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= '2021-01-01')
     GROUP BY 
         ps_partkey) sb ON ps.ps_partkey = sb.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_partkey = rs.ps_partkey AND rs.balance_rank = 1
LEFT JOIN 
    MaxBalance rb ON ps.ps_partkey = rb.ps_partkey
WHERE 
    p.p_container IS NOT NULL 
    AND (ps.ps_availqty IS NULL OR ps.ps_availqty > 0) 
    AND EXISTS (SELECT 1 FROM RegionFilter rf WHERE rf.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = ANY (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ps.ps_partkey)))
ORDER BY 
    total_revenue DESC, top_supplier_name;
