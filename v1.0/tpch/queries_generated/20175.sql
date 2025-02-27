WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' 
        AND o.o_orderdate < '2024-01-01'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerMoney AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 0 
            ELSE c.c_acctbal 
        END AS adjusted_acctbal
    FROM 
        customer c
    WHERE 
        c.c_mktsegment IN ('BUILDING', 'FURNITURE')
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    COALESCE(r.o_totalprice, 0) AS order_total,
    COALESCE(si.total_supply_cost, 0) AS supply_cost,
    cm.c_name,
    ROW_NUMBER() OVER (PARTITION BY r.o_orderkey ORDER BY r.o_orderdate DESC) AS order_date_rank,
    CASE 
        WHEN si.unique_parts_supplied > 10 THEN 'Many Parts'
        ELSE 'Few Parts'
    END AS parts_status
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierInfo si ON si.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey = r.o_orderkey
        ) 
        LIMIT 1 
    )
LEFT JOIN 
    CustomerMoney cm ON cm.c_custkey = (
        SELECT o.o_custkey 
        FROM orders o 
        WHERE o.o_orderkey = r.o_orderkey
        LIMIT 1
    )
WHERE 
    r.order_rank <= 5
ORDER BY 
    r.o_orderkey DESC, order_date_rank ASC;
