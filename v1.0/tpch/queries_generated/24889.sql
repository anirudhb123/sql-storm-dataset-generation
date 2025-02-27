WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATEADD(DAY, -30, CURRENT_DATE) 
        AND o.o_orderstatus IN ('F', 'O')
),
SupplierParts AS (
    SELECT
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey
),
HighValueParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        sp.supplier_count,
        sp.total_supply_value
    FROM
        part p
    JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey
    WHERE
        p.p_retailprice > 
        (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT
    n.n_name AS nation,
    hp.p_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count,
    AVG(COALESCE(hp.total_supply_value, 0)) AS avg_supply_value,
    STRING_AGG(DISTINCT hp.p_comment, '; ') AS comments
FROM
    HighValueParts hp
JOIN
    lineitem l ON hp.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
WHERE
    n.n_regionkey IS NOT NULL
    AND hp.supplier_count > 1
    AND hp.total_supply_value IS NOT NULL
GROUP BY
    n.n_name, hp.p_name
HAVING
    SUM(CASE WHEN o.o_orderstatus IS NULL THEN 0 ELSE 1 END) > 0
ORDER BY
    customer_count DESC,
    hp.p_name
LIMIT 100;
