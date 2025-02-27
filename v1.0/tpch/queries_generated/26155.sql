WITH SupplierStringAggregation AS (
    SELECT 
        s.s_name,
        CONCAT(s.s_name, ' - ', s.s_address) AS supplier_info,
        STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', ps.ps_availqty, ')'), ', ') AS part_supply_info
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_name, s.s_address
),
CustomerOrderDetails AS (
    SELECT 
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(DISTINCT CONCAT(o.o_orderkey, ': ', o.o_orderdate), '; ') AS orders_details
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
),
RegionNationAnalysis AS (
    SELECT 
        r.r_name,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name, n.n_name
)

SELECT 
    s.supplier_info,
    c.c_name,
    c.total_orders,
    c.total_spent,
    r.r_name,
    r.n_name,
    r.total_suppliers,
    r.supplier_names,
    'Additional Remark: Highly valued suppliers and customers in region ' || r.r_name AS remarks
FROM SupplierStringAggregation s
JOIN CustomerOrderDetails c ON TRUE
JOIN RegionNationAnalysis r ON TRUE
WHERE c.total_spent > 10000
ORDER BY r.r_name, s.s_name;
