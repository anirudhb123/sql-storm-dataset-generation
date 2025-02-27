WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
HighValueSupply AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name,
        CASE 
            WHEN ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp) THEN 'Below Average'
            ELSE 'Above Average'
        END AS supply_cost_comparison
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp WHERE ps_supplycost IS NOT NULL)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
    HAVING COUNT(o.o_orderkey) > 0
),
SupplyAvailability AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(ps.ps_availqty) AS total_avainility,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_name
)
SELECT 
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    su.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(lo.total_spent) AS total_customer_spending,
    s.total_avainility,
    RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(lo.total_spent) DESC) AS customer_rank,
    CASE 
        WHEN s.total_avainility > 1000 THEN 'High Availability'
        WHEN s.total_avainility BETWEEN 500 AND 1000 THEN 'Moderate Availability'
        ELSE 'Low Availability'
    END AS availability_status,
    CASE 
        WHEN lo.order_count IS NULL THEN 'No Orders'
        ELSE CONCAT('Orders Count: ', lo.order_count)
    END AS order_summary
FROM CustomerOrders lo
RIGHT JOIN HighValueSupply hvs ON lo.o_orderkey = hvs.ps_partkey
LEFT JOIN RankedSuppliers su ON hvs.ps_suppkey = su.s_suppkey
LEFT JOIN part p ON hvs.ps_partkey = p.p_partkey
JOIN SupplyAvailability s ON s.unique_parts > 2
WHERE su.rank <= 5
GROUP BY c.c_name, su.s_name, p.p_name, s.total_avainility
ORDER BY total_customer_spending DESC NULLS LAST;
