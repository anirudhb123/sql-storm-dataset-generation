WITH PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        CONCAT(p.p_name, ' | ', p.p_brand, ' | ', p.p_type) AS full_description
    FROM part p
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS part_supply_count
    FROM supplier s
),
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_nationkey,
        c.c_phone,
        c.c_acctbal,
        c.c_mktsegment,
        c.c_comment,
        (SELECT COUNT(*) FROM orders o WHERE o.o_custkey = c.c_custkey) AS order_count
    FROM customer c
)
SELECT 
    pi.full_description,
    si.s_name AS supplier_name,
    si.s_acctbal AS supplier_account_balance,
    ci.c_name AS customer_name,
    ci.order_count,
    COUNT(li.l_orderkey) AS total_line_items,
    SUM(li.l_extendedprice) AS total_revenue
FROM PartInfo pi
JOIN partsupp ps ON pi.p_partkey = ps.ps_partkey
JOIN SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
JOIN lineitem li ON li.l_partkey = pi.p_partkey
JOIN orders o ON li.l_orderkey = o.o_orderkey
JOIN CustomerInfo ci ON o.o_custkey = ci.c_custkey
WHERE pi.p_retailprice > 20.00 AND ci.order_count > 5
GROUP BY pi.full_description, si.s_name, si.s_acctbal, ci.c_name, ci.order_count
ORDER BY total_revenue DESC, pi.full_description ASC;
