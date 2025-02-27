WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS acct_rank
    FROM supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 0
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size >= 10 AND p.p_size <= 20 THEN 'Medium'
            ELSE 'Large'
        END AS size_category
    FROM part p
    WHERE p.p_retailprice BETWEEN 50.00 AND 500.00
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        fs.s_suppkey,
        fs.s_name,
        fs.s_acctbal,
        fps.size_category,
        ps.ps_availqty,
        CASE 
            WHEN ps.ps_supplycost IS NULL THEN 0.00
            ELSE ps.ps_supplycost 
        END AS supply_cost
    FROM partsupp ps
    JOIN RankedSuppliers fs ON ps.ps_suppkey = fs.s_suppkey AND fs.acct_rank <= 3
    JOIN FilteredParts fps ON ps.ps_partkey = fps.p_partkey
)
SELECT 
    N.n_name AS nation_name,
    SUM(sp.ps_availqty * sp.supply_cost) AS total_supply_value,
    COUNT(DISTINCT sp.s_suppkey) AS unique_suppliers,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sp.supply_cost) AS median_supply_cost
FROM SupplierPartDetails sp
JOIN nation N ON sp.s_suppkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = sp.s_suppkey)
GROUP BY N.n_name
HAVING SUM(sp.ps_availqty) > (SELECT AVG(ps_availqty) FROM partsupp)
ORDER BY total_supply_value DESC
FETCH FIRST 10 ROWS ONLY
UNION ALL
SELECT 
    'Total' AS nation_name,
    SUM(sp.ps_availqty * sp.supply_cost),
    COUNT(DISTINCT sp.s_suppkey),
    NULL
FROM SupplierPartDetails sp
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.o_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_acctbal > 1000.00
    ) AND o.o_orderstatus = 'O'
)
AND sp.ps_availqty IS NOT NULL
ORDER BY 1;
