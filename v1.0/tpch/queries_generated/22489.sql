WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 5000

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE sh.level < 3
),
RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
OrderAnalysis AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        CASE 
            WHEN o.o_totalprice IS NULL THEN 'Unknown'
            WHEN o.o_totalprice < 1000 THEN 'Low Value'
            WHEN o.o_totalprice BETWEEN 1000 AND 5000 THEN 'Medium Value'
            ELSE 'High Value'
        END AS order_value_category,
        COUNT(li.l_orderkey) AS lineitem_count
    FROM orders o
    LEFT JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT 
    sh.s_name AS Supplier_Name,
    sh.s_acctbal AS Supplier_Account_Balance,
    rp.p_name AS Part_Name,
    rp.total_supplycost AS Total_Supply_Cost,
    oa.order_value_category AS Order_Value_Category,
    oa.lineitem_count AS Lineitem_Count
FROM SupplierHierarchy sh
FULL OUTER JOIN RankedParts rp ON sh.s_suppkey = rp.p_partkey
RIGHT JOIN OrderAnalysis oa ON oa.lineitem_count > 1
WHERE oa.order_value_category IS NOT NULL
  AND (rp.total_supplycost IS NULL OR rp.rank <= 10)
  AND (sh.s_acctbal > 10000 OR rp.p_brand LIKE 'Brand%')
ORDER BY sh.s_acctbal DESC, rp.total_supplycost DESC NULLS LAST;
