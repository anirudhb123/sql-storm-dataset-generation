WITH RecursiveSupplier AS (
    SELECT 
        s_suppkey, s_name, s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s_suppkey ORDER BY s_acctbal DESC) AS rn
    FROM 
        supplier
    WHERE 
        s_acctbal IS NOT NULL
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(line_item_summary.total_price) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN (
        SELECT 
            l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_price
        FROM 
            lineitem
        GROUP BY 
            l_orderkey
    ) line_item_summary ON o.o_orderkey = line_item_summary.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        total_orders > 0
), 
PartSupplierDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) IS NOT NULL
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey, c.c_name, c.total_orders, c.total_spent, c.avg_order_value,
        RANK() OVER (ORDER BY c.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders c
    WHERE 
        c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
), 
SupplierRegionRank AS (
    SELECT 
        s.s_suppkey,
        r.r_name,
        RANK() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rank_by_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name IS NOT NULL
)
SELECT 
    p.p_partkey, p.p_name, p.total_available_quantity, p.total_supply_cost,
    h.c_name AS high_value_customer_name, 
    sr.r_name AS supplier_region, sr.rank_by_balance,
    (CASE WHEN h.total_orders IS NULL THEN 'No Orders' ELSE 'Has Orders' END) AS order_status
FROM 
    PartSupplierDetails p
LEFT JOIN 
    HighValueCustomers h ON p.total_available_quantity > h.avg_order_value
FULL OUTER JOIN 
    SupplierRegionRank sr ON sr.rank_by_balance < 3 AND h.total_orders IS NOT NULL
WHERE 
    COALESCE(h.total_spent, 0) > 1000 AND
    (p.total_supply_cost < 5000 OR p.total_supply_cost IS NULL)
ORDER BY 
    p.total_available_quantity DESC, 
    h.total_spent DESC NULLS LAST;
