WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
), SupplierAggregates AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), LineItemStats AS (
    SELECT 
        l.l_partkey,
        SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS total_value_after_discount,
        COUNT(l.l_returnflag) AS return_count
    FROM lineitem l
    GROUP BY l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    CASE 
        WHEN spa.unique_suppliers IS NULL THEN 'No Suppliers'
        ELSE CONCAT(spa.unique_suppliers, ' Suppliers')
    END AS supplier_info,
    COALESCE(cust.total_spent, 0) AS total_spent_by_customer,
    lst.total_value_after_discount,
    CASE 
        WHEN lst.return_count > 5 THEN 'High Returns'
        ELSE 'Normal Returns'
    END AS return_category
FROM RankedParts p
LEFT JOIN SupplierAggregates spa ON p.price_rank = 1 AND spa.nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE' LIMIT 1)
LEFT JOIN CustomerOrders cust ON cust.order_count > 0 AND cust.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_mktsegment = 'BUILDING' AND c.c_acctbal > 100.00)
INNER JOIN LineItemStats lst ON p.p_partkey = lst.l_partkey
WHERE p.p_retailprice BETWEEN 100 AND 500
OR (p.p_comment LIKE '%fragile%' AND lst.return_count = 0)
ORDER BY p.p_retailprice DESC, return_category;
