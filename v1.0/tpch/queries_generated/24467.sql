WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT c.c_custkey) as customer_count,
        SUM(o.o_totalprice) as total_spent
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_discount * l.l_extendedprice) AS total_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_totalprice
    HAVING total_discount > 1000
)
SELECT 
    cr.region_name,
    cr.n_name,
    cr.customer_count,
    HVO.o_orderkey,
    HVO.o_totalprice,
    s.s_name AS top_supplier,
    s.rank_acctbal,
    s.part_count,
    COALESCE(s1.s_name, 'No Supplier') AS second_supplier,
    COALESCE(s1.s_acctbal, 0) AS second_supplier_acctbal
FROM CustomerRegion cr
LEFT JOIN RankedSuppliers s ON s.rank_acctbal = 1
LEFT JOIN RankedSuppliers s1 ON s1.rank_acctbal = 2 AND s1.part_count > 1
LEFT JOIN HighValueOrders HVO ON HVO.o_totalprice BETWEEN 5000 AND 10000
WHERE cr.customer_count > 0
  AND (s.s_acctbal IS NOT NULL OR s1.s_acctbal IS NULL)
ORDER BY cr.region_name, cr.customer_count DESC, HVO.o_totalprice;
