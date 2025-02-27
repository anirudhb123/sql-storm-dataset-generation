WITH CTE_Agg AS (
    SELECT
        p.p_partkey,
        p.p_name,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availability,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        p.p_partkey, p.p_name, s.s_name
    HAVING
        total_availability > 1000
), 
CTE_Region AS (
    SELECT
        r.r_regionkey,
        r.r_name
    FROM
        region r
)
SELECT
    ca.p_partkey,
    ca.p_name,
    ca.s_name,
    cr.r_name,
    CONCAT('Supplier: ', ca.s_name, ', Total Available: ', ca.total_availability, ', Total Supply Cost: ', FORMAT(ca.total_supplycost, 2)) AS detailed_info
FROM
    CTE_Agg ca
JOIN
    supplier s ON ca.s_name = s.s_name
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    CTE_Region cr ON n.n_regionkey = cr.r_regionkey
WHERE
    LENGTH(ca.p_name) BETWEEN 10 AND 30
ORDER BY
    ca.total_supplycost DESC, cr.r_name ASC;
