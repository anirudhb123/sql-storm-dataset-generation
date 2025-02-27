WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_totalprice IS NOT NULL
),
HighValueLines AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM lineitem l
    WHERE l.l_discount BETWEEN 0.05 AND 0.1
    GROUP BY l.l_orderkey
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COALESCE(NULLIF(s.s_phone, ''), 'No Phone') AS normalized_phone,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > (SELECT AVG(c.c_acctbal) FROM customer c WHERE c.c_mktsegment = 'BUILDING')
    GROUP BY s.s_suppkey, s.s_name, s.s_phone
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_customer_spent,
        COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
),
FilteredSuppliers AS (
    SELECT
        sd.s_suppkey,
        sd.s_name,
        sd.total_supply_cost,
        RANK() OVER (ORDER BY sd.total_supply_cost DESC) AS supplier_rank
    FROM SupplierDetails sd
    WHERE sd.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierDetails)
),
ValidOrders AS (
    SELECT
        ro.o_orderkey,
        ro.o_orderstatus,
        ro.o_totalprice,
        CASE 
            WHEN EXISTS (SELECT 1 FROM HighValueLines hl WHERE hl.l_orderkey = ro.o_orderkey) THEN 'High Value'
            ELSE 'Regular'
        END AS order_type
    FROM RankedOrders ro
    WHERE ro.order_rank <= 10
)
SELECT
    co.c_custkey,
    co.c_name,
    vo.o_orderkey,
    vo.o_orderstatus,
    vo.o_totalprice,
    fs.s_name AS supplier_name,
    fs.total_supply_cost
FROM CustomerOrders co
JOIN ValidOrders vo ON co.total_customer_spent > 1000
LEFT JOIN FilteredSuppliers fs ON fs.supplier_rank <= 5
WHERE vo.o_orderstatus IN ('O', 'F')
ORDER BY co.c_custkey, vo.o_orderkey;
