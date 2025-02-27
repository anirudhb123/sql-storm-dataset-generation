WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey IN (SELECT DISTINCT n_nationkey FROM supplier)
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_regionkey
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        AVG(p.p_retailprice) AS avg_retail_price
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    nh.n_name AS nation_name,
    ps.p_name AS part_name,
    ps.supplier_count,
    ps.total_supply_value,
    co.order_count,
    co.total_spent,
    rs.s_name AS top_supplier,
    rs.rank
FROM NationHierarchy nh
LEFT JOIN PartStats ps ON nh.n_nationkey = ps.p_partkey
LEFT JOIN CustomerOrders co ON nh.n_nationkey = co.c_custkey
LEFT JOIN RankedSuppliers rs ON ps.supplier_count > rs.rank
WHERE 
    (ps.total_supply_value IS NOT NULL OR co.total_spent IS NULL)
    AND (ps.avg_retail_price > 0 OR rs.rank < 10)
ORDER BY nation_name, part_name;
