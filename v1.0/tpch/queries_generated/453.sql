WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        AVG(s.s_acctbal) AS average_account_balance,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
),

HighValueSuppliers AS (
    SELECT 
        sp.s_suppkey, 
        sp.s_name,
        sp.total_value,
        r.r_name
    FROM 
        SupplierPerformance sp
    JOIN 
        nation n ON sp.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        sp.rank_value <= 5
)

SELECT 
    hvs.s_suppkey,
    hvs.s_name,
    hvs.total_value,
    COALESCE(r.r_comment, 'No comment available') AS region_comment,
    (SELECT COUNT(*)
     FROM orders o 
     WHERE o.o_custkey IN (
         SELECT c.c_custkey 
         FROM customer c 
         WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')) 
         AND o.o_orderstatus = 'O') AS total_orders
FROM 
    HighValueSuppliers hvs
LEFT JOIN 
    region r ON hvs.r_name = r.r_name
ORDER BY 
    hvs.total_value DESC 
LIMIT 10;
