
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS dr
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '12 months'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS num_parts,
        MAX(LENGTH(s.s_comment)) AS max_comment_length
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
ValidNation AS (
    SELECT 
        n.n_nationkey, 
        n.n_name,
        CASE 
            WHEN MAX(s.s_acctbal) IS NULL THEN 'No Balance'
            ELSE 'Has Balance'
        END AS balance_status
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey, 
        ro.o_totalprice,
        COUNT(li.l_orderkey) AS lineitem_count
    FROM 
        RankedOrders ro
    LEFT JOIN 
        lineitem li ON ro.o_orderkey = li.l_orderkey
    WHERE 
        ro.rn <= 10 
    GROUP BY 
        ro.o_orderkey, ro.o_totalprice
)
SELECT 
    n.n_name AS nation_name,
    sd.s_name AS supplier_name,
    hvo.o_orderkey,
    hvo.o_totalprice,
    CASE 
        WHEN hvo.lineitem_count IS NULL THEN 'Lineitem Missing'
        ELSE CONCAT(hvo.lineitem_count::VARCHAR, ' Lineitems')
    END AS lineitem_status,
    'Order Priority: ' || COALESCE(ro.o_orderpriority, 'Normal') AS order_priority
FROM 
    ValidNation n
FULL OUTER JOIN 
    SupplierDetails sd ON n.balance_status = 'Has Balance'
LEFT JOIN 
    HighValueOrders hvo ON sd.s_suppkey = hvo.o_orderkey
LEFT JOIN 
    RankedOrders ro ON hvo.o_orderkey = ro.o_orderkey
WHERE 
    sd.total_cost > 10000
    OR n.n_name LIKE 'A%'
ORDER BY 
    n.n_name, sd.s_name, hvo.o_totalprice DESC
LIMIT 50;
