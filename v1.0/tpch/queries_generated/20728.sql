WITH RECURSIVE CTE_Orders AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS rn
    FROM orders
    WHERE o_orderdate >= DATE '1998-01-01'
),
CTE_Suppliers AS (
    SELECT s_suppkey, s_name, s_acctbal,
           SUM(ps_supplycost * ps_availqty) OVER (PARTITION BY s_suppkey) AS total_supply_cost
    FROM supplier
    JOIN partsupp ON s_suppkey = ps_suppkey
    WHERE s_acctbal > 5000
),
PART_CTE AS (
    SELECT p_partkey, p_name, p_retailprice,
           CASE WHEN p_size IS NULL THEN 'unknown' ELSE CAST(p_size AS VARCHAR) END AS part_size,
           COUNT(DISTINCT ps_suppkey) AS supplier_count
    FROM part
    LEFT JOIN partsupp ON p_partkey = ps_partkey
    GROUP BY p_partkey, p_name, p_retailprice, p_size
),
LINEITEM_AGG AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS revenue,
           AVG(l_quantity) AS avg_quantity,
           MAX(l_discount) AS max_discount
    FROM lineitem
    WHERE l_returnflag = 'N'
    GROUP BY l_orderkey
)

SELECT 
    CTE_Orders.o_orderkey,
    CTE_Orders.o_totalprice,
    CTE_Orders.o_orderdate,
    COALESCE(CTE_Suppliers.s_name, 'No Supplier') AS supplier_name,
    PART_CTE.part_name,
    PART_CTE.part_size,
    LINEITEM_AGG.revenue,
    CASE 
        WHEN LINEITEM_AGG.avg_quantity < 10 THEN 'Low Quantity'
        WHEN LINEITEM_AGG.avg_quantity BETWEEN 10 AND 20 THEN 'Medium Quantity'
        ELSE 'High Quantity'
    END AS quantity_category,
    (SELECT COUNT(DISTINCT c_custkey)
     FROM customer
     WHERE c_nationkey = (SELECT n_nationkey 
                          FROM nation 
                          WHERE n_name = 'FRANCE')) AS french_customers
FROM CTE_Orders
LEFT JOIN CTE_Suppliers ON CTE_Orders.o_custkey = CTE_Suppliers.s_suppkey
LEFT JOIN PART_CTE ON CTE_Suppliers.s_suppkey = PART_CTE.p_partkey
LEFT JOIN LINEITEM_AGG ON CTE_Orders.o_orderkey = LINEITEM_AGG.l_orderkey
WHERE CTE_Orders.rn = 1
AND (PART_CTE.supplier_count > 0 OR PART_CTE.supplier_count IS NULL)
ORDER BY CTE_Orders.o_orderdate DESC, revenue DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM orders) / 4;
