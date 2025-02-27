WITH RECURSIVE RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
),
TotalOrderValues AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_value,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice) 
        FROM orders o2 
        WHERE o2.o_orderdate >= DATE '2022-01-01'
    )
),
SupplierPartCounts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(sp.supplier_count, 0) AS supplier_count,
    COALESCE(o.total_value, 0) AS customer_order_value,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    COALESCE(r.rank, 0) AS supplier_rank
FROM part p
LEFT JOIN SupplierPartCounts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN HighValueOrders o ON o.o_orderkey IN (
    SELECT l.l_orderkey 
    FROM lineitem l 
    WHERE l.l_partkey = p.p_partkey
)
LEFT JOIN RankedSuppliers r ON r.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps 
    WHERE ps.ps_partkey = p.p_partkey
    AND ps.ps_availqty > 0
)
LEFT JOIN supplier s ON s.s_suppkey = r.s_suppkey
ORDER BY p.p_partkey, supplier_rank DESC;
