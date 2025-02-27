WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        CONCAT(s.s_name, ' - ', s.s_address) AS supplier_info,
        LENGTH(s.s_comment) AS comment_length
    FROM supplier s
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_phone,
        c.c_acctbal,
        c.c_mktsegment,
        SUBSTRING(c.c_comment, 1, 20) AS short_comment
    FROM customer c
),
PartSupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        COUNT(ps.ps_suppkey) AS total_suppliers,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        CASE 
            WHEN o.o_totalprice >= 500 THEN 'High Value'
            ELSE 'Normal Value'
        END AS order_value_category
    FROM orders o
)
SELECT 
    sd.supplier_info,
    cd.c_name,
    cd.short_comment,
    p.ps_partkey,
    p.total_suppliers,
    p.avg_supply_cost,
    o.o_orderkey,
    o.o_orderdate,
    o.order_value_category
FROM SupplierDetails sd
JOIN CustomerDetails cd ON sd.s_acctbal > cd.c_acctbal
JOIN PartSupplierSummary p ON p.total_suppliers > 5
JOIN OrderDetails o ON o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.ps_partkey)
WHERE sd.comment_length > 50
ORDER BY o.o_orderdate DESC, p.avg_supply_cost ASC;
