
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierParts AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        s.s_name,
        s.s_acctbal,
        p.p_retailprice,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM
        partsupp ps
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
PremiumCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS true_premium
    FROM
        customer c
    WHERE
        c.c_acctbal > 10000.00
),
SalesSummary AS (
    SELECT
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        lineitem l
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderstatus = 'F'
    GROUP BY
        l.l_partkey
)
SELECT
    rp.o_orderkey,
    rp.o_orderdate,
    rp.o_totalprice,
    rp.o_orderstatus,
    sp.p_name,
    sp.s_name,
    sp.ps_availqty,
    sp.ps_supplycost,
    pc.c_name AS premium_customer_name,
    ss.total_sales,
    ss.order_count
FROM
    RankedOrders rp
LEFT JOIN
    SupplierParts sp ON sp.ps_partkey = (
        SELECT ps_partkey 
        FROM partsupp 
        WHERE ps_supplycost = (
            SELECT MIN(ps_supplycost) 
            FROM partsupp 
            WHERE ps_partkey = sp.ps_partkey
        ) 
        LIMIT 1
    )
LEFT JOIN
    PremiumCustomers pc ON pc.true_premium <= 10
LEFT JOIN
    SalesSummary ss ON ss.l_partkey = sp.ps_partkey
WHERE
    rp.order_rank <= 5
ORDER BY
    rp.o_orderdate DESC, 
    rp.o_totalprice DESC;
