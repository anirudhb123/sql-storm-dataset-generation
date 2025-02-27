WITH RECURSIVE Combinations AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, 
           CONCAT('Part: ', p.p_name, ', Supplier Cost: ', CAST(ps.ps_supplycost AS VARCHAR(20))) AS Details
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    UNION ALL
    SELECT c.c_custkey, c.c_name, ps.ps_supplycost,
           CONCAT(D c.Details, ', Customer: ', c.c_name) AS Details
    FROM Combinations c
    JOIN customer cust ON c.p_partkey % (cust.c_custkey + 1) = 0
    JOIN partsupp ps ON ps.ps_partkey = c.p_partkey
    WHERE CHAR_LENGTH(c.Details) < 200
)
SELECT Details
FROM Combinations
WHERE Details LIKE '%Supplier%'
ORDER BY CHAR_LENGTH(Details) DESC
LIMIT 10;
