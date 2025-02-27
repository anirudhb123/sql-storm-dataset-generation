
WITH RECURSIVE part_supplier AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        p.p_name,
        p.p_brand,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM
        partsupp ps
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    WHERE
        ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
),
part_supplier_filtered AS (
    SELECT
        ps.p_name,
        ps.p_brand,
        SUM(ps.ps_availqty) AS total_avail,
        MAX(s.s_acctbal) AS max_supplier_acctbal,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        ps.ps_partkey
    FROM
        part_supplier ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE
        ps.rn = 1
    GROUP BY
        ps.p_name, ps.p_brand, ps.ps_partkey
)
SELECT
    p.p_name,
    p.p_brand,
    psf.total_avail,
    psf.max_supplier_acctbal,
    COALESCE(CASE WHEN psf.supplier_count > 5 THEN 'High Supply' ELSE 'Low Supply' END, 'Unknown Supply') AS supply_range,
    CASE 
        WHEN psf.total_avail IS NULL THEN 'No Availability'
        WHEN psf.max_supplier_acctbal IS NULL THEN 'No Supplier'
        ELSE 'Available'
    END AS availability_status
FROM
    part p
LEFT JOIN
    part_supplier_filtered psf ON p.p_partkey = psf.ps_partkey
WHERE
    EXISTS (
        SELECT 1
        FROM lineitem l
        WHERE l.l_partkey = p.p_partkey
        AND l.l_quantity > (
            SELECT MAX(l2.l_quantity) * 0.5 FROM lineitem l2 WHERE l2.l_partkey = p.p_partkey
        )
    )
ORDER BY
    p.p_partkey DESC
LIMIT 10;
