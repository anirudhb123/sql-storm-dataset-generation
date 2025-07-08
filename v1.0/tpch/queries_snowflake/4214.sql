WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
OrderInfo AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate, 
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
LineItemStats AS (
    SELECT 
        l.l_orderkey, 
        COUNT(*) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name,
    n.n_name,
    si.s_name,
    oi.o_orderkey,
    oi.o_totalprice,
    lis.item_count,
    lis.total_line_value,
    si.total_supply_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierInfo si ON n.n_nationkey = si.s_suppkey
JOIN 
    OrderInfo oi ON oi.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
LEFT JOIN 
    LineItemStats lis ON oi.o_orderkey = lis.l_orderkey
WHERE 
    si.total_supply_cost IS NOT NULL
    AND (oi.o_totalprice > 10000 OR lis.item_count > 5)
ORDER BY 
    r.r_name, n.n_name, oi.o_totalprice DESC;
