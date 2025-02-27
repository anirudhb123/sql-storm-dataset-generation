WITH RECURSIVE Supply_Summary AS (
    SELECT
        ps_partkey,
        ps_suppkey,
        ps_availqty,
        ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS rn
    FROM
        partsupp
    WHERE
        ps_availqty > 0
),
Customer_Orders AS (
    SELECT
        o.o_orderkey,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_orderkey) AS total_lines
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderstatus = 'O' AND l.l_shipdate < CURRENT_DATE - INTERVAL '30 days'
    GROUP BY
        o.o_orderkey, c.c_custkey
),
Supplier_Info AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        COALESCE(NULLIF(s.s_comment, ''), 'No additional comments') AS safe_comment,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM
        supplier s
    LEFT JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, r.r_name, safe_comment
)
SELECT
    cs.o_orderkey,
    cs.c_custkey,
    ss.ps_partkey,
    si.s_name AS supplier_name,
    si.region_name,
    si.safe_comment,
    COALESCE(cs.revenue, 0) AS total_revenue,
    si.parts_supplied,
    CASE 
        WHEN si.parts_supplied > 0 THEN (si.parts_supplied / NULLIF(COUNT(cs.o_orderkey), 0)) * 100
        ELSE 0
    END AS supply_ratio
FROM
    Customer_Orders cs
LEFT JOIN
    Supply_Summary ss ON cs.o_orderkey = ss.ps_partkey
JOIN
    Supplier_Info si ON ss.ps_suppkey = si.s_suppkey
WHERE
    si.parts_supplied > 1 OR cs.total_lines > 5
ORDER BY
    total_revenue DESC, supply_ratio DESC
LIMIT 100;
