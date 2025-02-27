WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 20
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        MAX(ps.ps_supplycost) AS max_supply_cost,
        MIN(ps.ps_supplycost) AS min_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey
),
OrderLineAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    p1.p_name,
    p1.rn AS part_rank,
    cos.c_custkey,
    cos.total_orders,
    cos.total_spent,
    spa.supplied_parts,
    spa.max_supply_cost,
    spa.min_supply_cost,
    ola.total_revenue,
    ola.total_returned
FROM RankedParts p1
LEFT JOIN CustomerOrderStats cos ON p1.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
LEFT JOIN SupplierPartDetails spa ON spa.supplied_parts > 5
LEFT JOIN OrderLineAggregates ola ON ola.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
WHERE p1.p_retailprice <= ALL (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size = p1.p_size)
  AND EXISTS (SELECT 1 FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = cos.c_custkey) AND n.n_name LIKE 'A%')
ORDER BY p1.p_name, cos.total_spent DESC
LIMIT 100 OFFSET 10;
