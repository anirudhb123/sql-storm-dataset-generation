WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= (CURRENT_DATE - INTERVAL '1 year')
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        COALESCE(ps.ps_availqty, 0) AS available_quantity
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
TotalLineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM lineitem l
    WHERE l.l_shipdate >= '2022-01-01' AND l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT 
    ns.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(cs.total_spent) AS average_spent,
    SUM(tl.total_price) AS total_lineitem_value,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' - ', p.p_name) ORDER BY s.s_name) AS supplier_parts
FROM nation ns
LEFT JOIN customer c ON c.c_nationkey = ns.n_nationkey
LEFT JOIN CustomerSummary cs ON c.c_custkey = cs.c_custkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN TotalLineItemDetails tl ON o.o_orderkey = tl.l_orderkey
LEFT JOIN SupplierPartDetails spd ON spd.ps_supplycost < 100.00
WHERE cs.total_spent IS NOT NULL
GROUP BY ns.n_name
ORDER BY total_lineitem_value DESC
LIMIT 10;
