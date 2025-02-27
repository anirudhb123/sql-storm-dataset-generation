
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'N/A' 
            ELSE CAST(c.c_acctbal AS CHAR)
        END AS account_balance
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL OR c.c_name LIKE 'A%'
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    co.c_name AS customer_name,
    rs.o_orderkey,
    rs.o_orderdate,
    rs.o_totalprice,
    COUNT(ls.l_orderkey) AS total_line_items,
    sd.supplied_parts,
    SUM(ls.total_value) AS total_lineitem_value
FROM RankedOrders rs
JOIN CustomerInfo co ON rs.o_orderkey = co.c_custkey
LEFT JOIN LineItemStats ls ON rs.o_orderkey = ls.l_orderkey
LEFT JOIN SupplierDetails sd ON ls.l_orderkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
WHERE co.account_balance IS NOT NULL
  AND rs.order_rank <= 5
GROUP BY co.c_name, rs.o_orderkey, rs.o_orderdate, rs.o_totalprice, sd.supplied_parts
ORDER BY rs.o_orderdate DESC, total_line_items DESC;
