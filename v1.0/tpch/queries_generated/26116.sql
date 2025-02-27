WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation,
        r.r_name AS region,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT p.p_partkey) AS unique_parts,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name, 
        r.r_name, 
        s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(o.o_orderstatus, ', ') AS order_statuses
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    sd.s_name AS supplier_name,
    sd.nation AS supplier_nation,
    sd.region AS supplier_region,
    sd.total_available AS supplier_total_available,
    sd.unique_parts AS supplier_unique_parts,
    sd.part_names AS supplier_parts,
    co.c_name AS customer_name,
    co.total_orders AS customer_total_orders,
    co.total_spent AS customer_total_spent,
    co.order_statuses AS customer_order_statuses
FROM SupplierDetails sd
JOIN CustomerOrders co ON co.total_spent > sd.s_acctbal
WHERE sd.total_available > 1000
ORDER BY sd.s_name, co.total_spent DESC;
