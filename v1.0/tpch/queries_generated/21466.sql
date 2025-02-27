WITH RECURSIVE RegionSuppliers AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        s.s_suppkey,
        s.s_name,
        COALESCE(s.s_acctbal, 0) AS adjusted_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown'
            ELSE s.s_name 
        END AS supplier_name
    FROM
        nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE
        n.n_name LIKE 'A%'
    
    UNION ALL
    
    SELECT
        n.n_nationkey,
        n.n_name,
        s.s_suppkey,
        s.s_name,
        COALESCE(s.s_acctbal, 0) + 100 AS adjusted_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown'
            ELSE CONCAT(s.s_name, ' (adjusted)') 
        END AS supplier_name
    FROM
        nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE
        n.n_name NOT LIKE 'A%'
),
PartDetails AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) as retail_rank
    FROM
        part p
    WHERE
        p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost < 20.00)
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
    HAVING
        COUNT(o.o_orderkey) > 5
)
SELECT 
    r.n_name AS nation_name,
    r.supplier_name,
    p.p_name AS product_name,
    pd.retail_rank,
    c.c_name AS customer_name,
    c.total_orders,
    c.total_spent,
    CASE 
        WHEN c.total_spent IS NULL THEN 'No Orders'
        ELSE CAST(c.total_spent AS VARCHAR(20))
    END AS spend_label
FROM 
    RegionSuppliers r
FULL OUTER JOIN PartDetails p ON r.s_supplier_name = p.p_name
INNER JOIN CustomerOrders c ON c.total_orders > 0
WHERE
    (r.n_name IS NOT NULL OR c.c_name IS NOT NULL)
    AND (r.supplier_name IS NOT NULL OR p.p_name IS NOT NULL)
ORDER BY
    spend_label DESC NULLS LAST, retail_rank;
