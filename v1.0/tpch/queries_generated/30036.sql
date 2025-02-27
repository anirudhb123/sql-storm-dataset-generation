WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS lvl
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, oh.o_custkey, oh.o_orderdate, oh.o_totalprice, lvl + 1
    FROM OrderHierarchy oh
    JOIN orders o ON oh.o_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
SupplierStats AS (
    SELECT 
        ps.s_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        MIN(ps.ps_availqty) AS min_avail_qty,
        MAX(ps.ps_availqty) AS max_avail_qty
    FROM partsupp ps
    GROUP BY ps.s_suppkey
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
)
SELECT 
    p.p_name,
    s.s_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(c.c_acctbal) AS avg_account_balance,
    MAX(s.total_supply_cost) AS max_supply_cost,
    MIN(s.min_avail_qty) AS min_avail_qty,
    COUNT(DISTINCT cd.c_custkey) AS unique_customers
FROM 
    lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN part p ON p.p_partkey = ps.ps_partkey
LEFT JOIN CustomerDetails cd ON o.o_custkey = cd.c_custkey
LEFT JOIN SupplierStats s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    l.l_shipdate >= '2023-01-01' AND 
    l.l_shipdate < '2023-12-31' AND 
    p.p_size BETWEEN 10 AND 20 AND
    s.total_supply_cost IS NOT NULL
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue DESC, 
    order_count DESC;
