WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) as rn
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
), OrderLineDetails AS (
    SELECT 
        co.c_custkey,
        co.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM CustomerOrders co
    JOIN lineitem l ON co.o_orderkey = l.l_orderkey
    GROUP BY co.c_custkey, co.o_orderkey
), SupplierSummary AS (
    SELECT 
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 1 AND 12
    GROUP BY p.p_brand
), ImportantNations AS (
    SELECT 
        n.n_name, 
        RANK() OVER (ORDER BY COUNT(s.s_suppkey) DESC) as nation_rank
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
    HAVING COUNT(s.s_suppkey) > 10
), OrderStats AS (
    SELECT 
        co.c_custkey,
        COALESCE(SUM(l.l_extendedprice), 0) AS total_revenue,
        AVG(l.l_quantity) AS average_quantity,
        MAX(l.l_discount) AS max_discount,
        CASE 
            WHEN COUNT(DISTINCT l.l_partkey) > 3 THEN 'Diverse'
            ELSE 'Limited'
        END AS diversity_status
    FROM CustomerOrders co
    LEFT JOIN lineitem l ON co.o_orderkey = l.l_orderkey
    GROUP BY co.c_custkey
)
SELECT 
    cs.c_name,
    cs.o_orderkey,
    cs.o_orderdate,
    os.total_revenue,
    ss.total_supply_cost,
    ss.supplier_count,
    os.average_quantity,
    os.diversity_status,
    CASE 
        WHEN ns.nation_rank = 1 THEN 'Top Nation' 
        ELSE 'Other Nation' 
    END AS nation_status
FROM CustomerOrders cs
JOIN OrderStats os ON cs.c_custkey = os.c_custkey
LEFT JOIN SupplierSummary ss ON cs.o_orderkey = ss.p_brand
LEFT JOIN ImportantNations ns ON cs.c_custkey = ns.n_name
WHERE cs.rn = 1
  AND (os.total_revenue IS NOT NULL OR ss.total_supply_cost IS NOT NULL)
ORDER BY cs.o_orderdate DESC, os.total_revenue DESC;
