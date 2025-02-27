WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        COALESCE(CAST(SUBSTRING(c.c_name, 1, 3) AS varchar), 'UNK') AS cust_initials
    FROM 
        orders o
    LEFT JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
SupplyDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
PotentialSuppliers AS (
    SELECT 
        p.p_partkey,
        s.s_suppkey,
        s.s_name,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'NO BALANCE' 
            ELSE 'BALANCE PRESENT' 
        END AS account_status
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal >= (SELECT AVG(s2.s_acctbal) FROM supplier s2)
        OR s.s_comment LIKE '%urgent%'
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipmode IN ('AIR', 'RAIL')
        AND l.l_returnflag IS NULL
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    s.total_supply_cost,
    p.s_name,
    f.net_revenue,
    f.unique_parts_count,
    r.cust_initials
FROM 
    RankedOrders r
LEFT JOIN 
    SupplyDetails s ON r.o_orderkey = (SELECT MAX(l.l_orderkey) FROM lineitem l WHERE l.l_orderkey = r.o_orderkey)
LEFT JOIN 
    PotentialSuppliers p ON p.p_partkey = (SELECT MAX(ps.ps_partkey) FROM partsupp ps)
LEFT JOIN 
    FilteredLineItems f ON r.o_orderkey = f.l_orderkey
WHERE 
    r.order_rank <= 10
    AND (s.total_supply_cost IS NOT NULL OR p.account_status = 'BALANCE PRESENT')
ORDER BY 
    r.o_totalprice DESC NULLS LAST
LIMIT 50;
