WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
    AND o.o_orderdate < DATE '2023-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerRegion AS (
    SELECT
        c.c_custkey,
        c.c_name,
        r.r_name,
        c.c_acctbal
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE c.c_acctbal IS NOT NULL
),
FilteredPartSupp AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 
        (SELECT AVG(total_cost) FROM (
            SELECT SUM(ps_supplycost * ps_availqty) AS total_cost 
            FROM partsupp 
            GROUP BY ps_partkey) subquery)
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    cust.c_name,
    r.r_name AS customer_region,
    supp.s_name AS supplier_name,
    CASE 
        WHEN x.total_cost IS NULL THEN 'Cost Unavailable'
        ELSE CAST(x.total_cost AS VARCHAR)
    END AS total_cost_supplier,
    RANK() OVER (PARTITION BY cust.c_nationkey ORDER BY o.o_totalprice DESC) AS price_rank
FROM RankedOrders o
JOIN CustomerRegion cust ON o.o_custkey = cust.c_custkey
LEFT JOIN FilteredPartSupp x ON x.ps_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey LIMIT 1)
LEFT JOIN SupplierDetails supp ON supp.s_nationkey = cust.n_nationkey
WHERE o.o_orderstatus IN ('F', 'P') 
  AND (o.o_totalprice > 1000 OR EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_orderkey = o.o_orderkey AND l.l_discount >= 0.1))
ORDER BY o.o_orderdate DESC, price_rank;
