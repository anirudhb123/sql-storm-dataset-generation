WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_clerk,
        o.o_shippriority,
        1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT 
        o.o_orderkey,
        oh.o_orderstatus,
        oh.o_totalprice,
        oh.o_orderdate,
        oh.o_orderpriority,
        oh.o_clerk,
        oh.o_shippriority,
        order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.o_orderstatus = 'F'
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrderInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationRegion AS (
    SELECT 
        n.n_name,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
)
SELECT 
    p.p_name,
    psi.total_supply_cost,
    psi.supplier_count,
    coi.total_spent,
    nr.n_name,
    nr.r_name,
    ROW_NUMBER() OVER (PARTITION BY nr.r_name ORDER BY psi.total_supply_cost DESC) AS supplier_rank,
    COALESCE(coi.total_spent, 0) AS customer_spending,
    CASE 
        WHEN coi.total_spent IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    SUM(CASE WHEN li.l_discount > 0 THEN li.l_extendedprice * (1 - li.l_discount) ELSE li.l_extendedprice END) AS total_revenue
FROM PartSupplierInfo psi
JOIN CustomerOrderInfo coi ON psi.p_partkey = coi.c_custkey
JOIN NationRegion nr ON coi.c_custkey = nr.supplier_count
LEFT JOIN lineitem li ON li.l_partkey = psi.p_partkey
GROUP BY p.p_name, psi.total_supply_cost, psi.supplier_count, coi.total_spent, nr.n_name, nr.r_name
HAVING SUM(li.l_quantity) > 100
ORDER BY nr.r_name, supplier_rank;
