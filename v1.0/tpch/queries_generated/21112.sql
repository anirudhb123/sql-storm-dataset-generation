WITH RECURSIVE RankedParts AS (
    SELECT 
        p_partkey,
        p_name,
        p_mfgr,
        p_brand,
        p_type,
        p_size,
        p_container,
        p_retailprice,
        p_comment,
        ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) AS brand_rank
    FROM part
),
SupplierStatistics AS (
    SELECT 
        s_nationkey,
        COUNT(DISTINCT s_suppkey) AS supplier_count,
        AVG(s_acctbal) AS avg_acctbal,
        SUM(CASE WHEN s_acctbal > 5000 THEN 1 ELSE 0 END) AS high_value_suppliers
    FROM supplier
    GROUP BY s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
NationalParts AS (
    SELECT 
        n.n_name,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY p.p_retailprice DESC) AS national_rank,
        COALESCE(s.s_name, 'Unknown Supplier') AS supplier_info
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
OrderLineStats AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS line_item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        MAX(l.l_receiptdate) AS latest_receipt_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
BizarreQuery AS (
    SELECT 
        np.n_name,
        COUNT(DISTINCT np.p_name) AS part_count,
        MAX(CASE WHEN cs.total_spent IS NULL THEN 0 ELSE cs.total_spent END) AS max_customer_spending,
        SUM(CASE WHEN os.line_item_count > 0 THEN 1 ELSE 0 END) AS order_line_present
    FROM NationalParts np
    LEFT JOIN CustomerOrders cs ON np.n_name = (SELECT n_name FROM nation WHERE n_nationkey = cs.c_custkey % (SELECT COUNT(*) FROM nation))
    LEFT JOIN OrderLineStats os ON os.o_orderkey = (SELECT MIN(o_orderkey) FROM orders WHERE o_orderkey % 2 = 0)
    GROUP BY np.n_name
)
SELECT 
    bq.n_name,
    bq.part_count,
    bq.max_customer_spending,
    bq.order_line_present
FROM BizarreQuery bq
WHERE bq.part_count > 5 
  AND (bq.max_customer_spending IS NULL OR bq.max_customer_spending < (SELECT AVG(total_spent) FROM CustomerOrders))
ORDER BY bq.n_name;
