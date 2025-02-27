WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier 
        WHERE s_nationkey = s.s_nationkey
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < (
        SELECT AVG(s_acctbal)
        FROM supplier 
        WHERE s_nationkey = s.n_nationkey
    )
),
PriceDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
    GROUP BY p.p_partkey, p.p_name
),
DetailedReport AS (
    SELECT 
        n.n_name AS nation,
        p.p_name,
        pd.total_cost,
        pd.avg_price,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY pd.avg_price DESC) AS rank
    FROM PriceDetails pd
    JOIN supplier s ON pd.total_cost > s.s_acctbal
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_comment IS NOT NULL OR n.n_comment LIKE '%important%'
)
SELECT 
    dr.nation,
    dr.p_name,
    dr.total_cost,
    dr.avg_price,
    CASE 
        WHEN dr.rank <= 5 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_type
FROM 
    DetailedReport dr
LEFT JOIN 
    region r ON r.r_regionkey = (SELECT n.r_regionkey FROM nation n WHERE n.n_name = dr.nation)
WHERE 
    r.r_name IS NOT NULL
ORDER BY 
    dr.nation, dr.avg_price DESC;
