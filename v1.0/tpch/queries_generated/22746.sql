WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
PartAvailability AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MAX(l.l_shipdate) AS last_ship_date
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
      AND l.l_discount > 0.05 
    GROUP BY l.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(pa.total_avail_qty, 0) AS available_quantity,
    pa.avg_supply_cost,
    cs.total_orders,
    cs.total_spent,
    FIRST_VALUE(rs.s_name) OVER (PARTITION BY cn.n_nationkey ORDER BY rs.rn) AS top_supplier_name,
    li.total_revenue,
    li.last_ship_date
FROM PartAvailability pa
FULL OUTER JOIN CustomerOrders cs ON pa.total_avail_qty > cs.total_spent
LEFT JOIN RankedSuppliers rs ON cs.total_orders > 10 AND cs.total_spent IS NOT NULL
JOIN region r ON r.r_regionkey = (SELECT rn.r_regionkey 
                                   FROM nation rn 
                                   WHERE rn.n_nationkey IN (SELECT DISTINCT c.c_nationkey FROM customer c))
LEFT JOIN FilteredLineItems li ON cs.total_orders < 5 AND cs.c_custkey = (SELECT MAX(c.c_custkey) FROM customer c)
WHERE pa.avg_supply_cost IS NOT NULL
  AND (li.total_revenue BETWEEN 1000 AND 5000 OR li.total_revenue IS NULL)
ORDER BY p.p_partkey, available_quantity DESC;
