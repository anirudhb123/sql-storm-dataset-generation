WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS BalanceRank
    FROM supplier s
),
HighBalanceSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM RankedSuppliers s
    WHERE s.BalanceRank <= 3
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        H.s_name AS supplier_name
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN HighBalanceSuppliers H ON ps.ps_suppkey = H.s_suppkey
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS total_parts
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY l.l_orderkey
),
SupplierOrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        COALESCE(SUM(pi.ps_supplycost * pi.ps_availqty), 0) AS total_supply_cost,
        COUNT(pi.p_partkey) AS number_of_parts
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN PartSupplierInfo pi ON l.l_partkey = pi.p_partkey
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_totalprice
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    SUM(COALESCE(oss.total_supply_cost, 0)) AS total_cost,
    AVG(o.o_totalprice) AS avg_order_price,
    MAX(o.o_orderkey) AS max_order_key,
    CASE 
        WHEN COUNT(o.o_orderkey) > 0 THEN 'Orders Placed'
        ELSE 'No Orders'
    END AS order_status
FROM supplier s
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN SupplierOrderStats oss ON s.s_suppkey = oss.o_orderkey
GROUP BY n.n_name
HAVING SUM(COALESCE(oss.total_supply_cost, 0)) > 1000 AND MAX(oss.number_of_parts) > 5
ORDER BY unique_suppliers DESC, total_cost ASC;
