WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1995-01-01' 
        AND o.o_orderdate <= '1996-12-31'
),
SupplierPartitioned AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty, 
        ps.ps_supplycost,
        SUM(ps.ps_supplycost) OVER (PARTITION BY ps.ps_partkey) AS total_supplycost
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty > 0
),
CustomerStats AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'UNKNOWN'
            ELSE 'KNOWNSUP'
        END AS acct_status
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (
            SELECT 
                AVG(s1.s_acctbal) 
            FROM 
                supplier s1
            WHERE 
                s1.s_nationkey = s.s_nationkey
        )
)
SELECT 
    r.order_key,
    c.c_name,
    sp.s_suppkey,
    CASE 
        WHEN r.price_rank = 1 THEN 'TOP_ORDER'
        ELSE 'OTHER_ORDER'
    END AS order_rank,
    COALESCE(sp.total_supplycost, 0) AS total_supplycost,
    f.acct_status
FROM 
    RankedOrders r
JOIN 
    CustomerStats c ON r.o_orderkey = c.c_custkey
LEFT JOIN 
    SupplierPartitioned sp ON r.o_orderkey = sp.ps_partkey
LEFT JOIN 
    FilteredSuppliers f ON sp.ps_suppkey = f.s_suppkey
WHERE 
    (c.order_count > 5 OR c.total_spent IS NULL)
    AND (f.acct_status = 'UNKNOWN' OR f.acct_status IS NOT NULL)
UNION ALL
SELECT 
    NULL AS order_key,
    'ALL CUSTOMERS' AS c_name,
    NULL AS s_suppkey,
    'AGGREGATED' AS order_rank,
    SUM(sp.total_supplycost) AS total_supplycost,
    'N/A' AS acct_status
FROM 
    FilteredSuppliers sp
GROUP BY 
    sp.s_nationkey;
