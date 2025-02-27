WITH RankedCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rnk
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2) 
    GROUP BY 
        s.s_suppkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_linenumber) AS line_count,
        MAX(l.l_shipdate) AS latest_shipdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
),
NationsWithComments AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        n.n_comment,
        ROW_NUMBER() OVER (ORDER BY n.n_nationkey) AS nation_rnk
    FROM 
        nation n
    WHERE 
        n.n_comment IS NOT NULL 
        OR LENGTH(n.n_comment) > 0
)
SELECT 
    rc.c_custkey,
    rc.c_name,
    ns.n_name,
    fs.avg_supplycost,
    od.total_price,
    COALESCE(od.line_count, 0) AS line_count,
    CASE 
        WHEN od.latest_shipdate > CURRENT_DATE - INTERVAL '30 days' THEN 'Recent Shipment'
        ELSE 'Older Shipment'
    END AS shipment_status
FROM 
    RankedCustomers rc
LEFT JOIN 
    NationsWithComments ns ON rc.c_nationkey = ns.n_nationkey
JOIN 
    FilteredSuppliers fs ON ns.n_nationkey = fs.s_suppkey
FULL OUTER JOIN 
    OrderDetails od ON rc.c_custkey = od.o_orderkey
WHERE 
    ns.nation_rnk < 5 
    AND (fs.avg_supplycost IS NULL OR fs.avg_supplycost < (SELECT AVG(avg_supplycost) FROM FilteredSuppliers))
ORDER BY 
    rc.c_name, od.total_price DESC, shipment_status;
