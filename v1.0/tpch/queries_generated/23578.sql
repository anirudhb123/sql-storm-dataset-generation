WITH RegionSummary AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM
        region r
    LEFT JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        r.r_regionkey, r.r_name
),
OrderStats AS (
    SELECT
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderdate >= DATE '2020-01-01' AND o.o_orderdate < DATE '2021-01-01'
    GROUP BY
        c.c_nationkey
),
PartSupplierStats AS (
    SELECT
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        part p
    INNER JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey
),
RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rank
    FROM
        part p
    WHERE
        p.p_retailprice IS NOT NULL
),
SuspiciousLines AS (
    SELECT
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        CASE
            WHEN l.l_quantity < 0 THEN 'Negative Quantity'
            WHEN l.l_returnflag = 'R' AND l.l_linestatus = 'O' THEN 'Returned Open Line'
            ELSE 'Valid'
        END AS line_status
    FROM
        lineitem l
    WHERE
        l.l_discount > 0.5 OR l.l_tax IS NULL
)
SELECT
    rs.r_name,
    rs.nation_count,
    rs.total_acctbal,
    os.total_spent,
    os.order_count,
    p.p_name,
    ps.total_avail_qty,
    ps.avg_supply_cost,
    rp.rank,
    sl.line_status
FROM
    RegionSummary rs
LEFT JOIN
    OrderStats os ON rs.r_regionkey = os.c_nationkey
JOIN
    PartSupplierStats ps ON ps.p_partkey IN (SELECT p.p_partkey FROM RankedParts p WHERE p.rank <= 5) 
LEFT JOIN 
    RankedParts rp ON ps.p_partkey = rp.p_partkey
LEFT JOIN 
    SuspiciousLines sl ON sl.l_orderkey = (SELECT MAX(l.l_orderkey) FROM lineitem l WHERE l.l_quantity = ps.total_avail_qty)
WHERE
    rs.total_acctbal IS NOT NULL AND os.total_spent IS NOT NULL
ORDER BY
    rs.r_name, os.total_spent DESC
LIMIT 50;
