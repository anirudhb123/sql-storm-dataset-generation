WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_mfgr,
        (p.p_retailprice * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND p.p_size BETWEEN 1 AND 10
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        COUNT(l.l_linenumber) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        AVG(l.l_discount) AS avg_discount,
        MAX(l.l_receiptdate) AS latest_receipt_date
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.c_name,
    sd.s_name,
    COALESCE(lis.item_count, 0) AS item_count,
    COALESCE(lis.total_value, 0) AS total_value,
    CASE 
        WHEN lis.avg_discount IS NOT NULL THEN ROUND(lis.avg_discount * 100, 2)
        ELSE NULL 
    END AS avg_discount_percentage,
    sd.total_cost AS supplier_total_cost
FROM 
    RankedOrders ro
LEFT JOIN 
    LineItemSummary lis ON ro.o_orderkey = lis.l_orderkey
LEFT JOIN 
    SupplierDetails sd ON sd.total_cost > 1000
WHERE 
    EXISTS (
        SELECT 1 
        FROM nation n 
        WHERE n.n_nationkey = ro.c_nationkey
          AND n.n_name NOT LIKE 'A%'
    )
ORDER BY 
    ro.o_orderdate DESC, 
    ro.o_orderkey
FETCH FIRST 10 ROWS ONLY;
