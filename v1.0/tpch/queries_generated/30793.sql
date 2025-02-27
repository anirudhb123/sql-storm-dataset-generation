WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, n.n_comment, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT p.p_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS items_sold,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS region_name,
    nh.n_name AS nation_name,
    s.s_name AS supplier_name,
    ss.total_parts,
    ss.total_cost,
    os.total_revenue,
    fc.c_name AS customer_name,
    fc.total_spent
FROM region r
LEFT JOIN NationHierarchy nh ON r.r_regionkey = nh.n_regionkey
LEFT JOIN SupplierStats ss ON nh.n_nationkey = (SELECT n.n_nationkey FROM supplier s JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 1000) LIMIT 1)
LEFT JOIN OrderSummary os ON os.revenue_rank <= 10
LEFT JOIN FilteredCustomers fc ON fc.total_spent > 5000
WHERE ss.total_cost IS NOT NULL OR fc.total_spent IS NULL
ORDER BY region_name, nation_name, supplier_name;
