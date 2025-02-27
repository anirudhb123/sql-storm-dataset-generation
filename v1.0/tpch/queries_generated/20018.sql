WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31'
),
SupplierMetrics AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
FilteredNation AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        CASE 
            WHEN n.n_name LIKE '%land%' THEN 'Flagged'
            ELSE 'Unflagged'
        END AS flag_status
    FROM 
        nation n
    WHERE 
        n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_comment IS NOT NULL)
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(NULLIF(p.p_comment, ''), 'No Comment') AS comment_detail
    FROM 
        part p
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    pm.p_name,
    sm.unique_parts_supplied,
    fn.flag_status
FROM 
    RankedOrders o
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    PartDetails pm ON l.l_partkey = pm.p_partkey
JOIN 
    SupplierMetrics sm ON sm.s_suppkey = l.l_suppkey
JOIN 
    FilteredNation fn ON fn.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_orderkey % 10)
WHERE 
    o.o_orderstatus IN ('O', 'F') 
    AND (o.o_totalprice > 100.00 OR l.l_discount > 0.1)
UNION ALL
SELECT 
    NULL AS o_orderkey,
    NULL AS o_orderdate,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS discounted_total,
    'Aggregate' AS p_name,
    NULL AS unique_parts_supplied,
    'Unflagged' AS flag_status
FROM 
    lineitem l
WHERE 
    l.l_shipdate < (SELECT MAX(o.o_orderdate) FROM orders o WHERE o.o_orderstatus = 'F')
GROUP BY 
    l.l_returnflag
ORDER BY 
    2 DESC, 4 ASC
