WITH RankedSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        s_acctbal,
        RANK() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rnk
    FROM supplier
), SupplierAvailability AS (
    SELECT 
        ps_partkey,
        ps_suppkey,
        SUM(ps_availqty) AS total_availqty,
        AVG(ps_supplycost) AS avg_supplycost
    FROM partsupp
    GROUP BY ps_partkey, ps_suppkey
), OrdersWithDiscount AS (
    SELECT 
        o_orderkey,
        o_totalprice,
        SUM(l_discount) / COUNT(l_discount) AS avg_discount
    FROM orders
    JOIN lineitem ON o_orderkey = l_orderkey
    GROUP BY o_orderkey, o_totalprice
), CustomerRegions AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_regionkey,
        r.r_name,
        CASE 
            WHEN r.r_name IS NULL THEN 'Unknown Region' 
            ELSE r.r_name 
        END AS effective_region
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
), EnhancedAvailability AS (
    SELECT 
        sa.ps_partkey,
        sa.ps_suppkey,
        sa.total_availqty,
        sa.avg_supplycost,
        rs.s_name,
        cs.effective_region,
        CASE 
            WHEN sa.total_availqty IS NULL THEN 0 
            ELSE sa.total_availqty 
        END AS adjusted_availqty
    FROM SupplierAvailability sa
    JOIN RankedSuppliers rs ON sa.ps_suppkey = rs.s_suppkey
    LEFT JOIN CustomerRegions cs ON rs.s_nationkey = cs.n_regionkey
    WHERE rs.rnk = 1
), FinalSelection AS (
    SELECT 
        ea.ps_partkey,
        ea.s_name,
        ea.adjusted_availqty,
        OWD.avg_discount,
        (ea.avg_supplycost * ea.adjusted_availqty) AS total_cost
    FROM EnhancedAvailability ea
    JOIN OrdersWithDiscount OWD ON ea.ps_partkey IN (
        SELECT DISTINCT l_partkey 
        FROM lineitem 
        WHERE l_orderkey IN (
            SELECT o_orderkey 
            FROM orders 
            WHERE o_orderstatus = 'F'
        )
    )
    WHERE ea.adjusted_availqty > (SELECT AVG(adjusted_availqty) FROM EnhancedAvailability)
    ORDER BY total_cost DESC
)
SELECT 
    DISTINCT fs.s_name,
    COUNT(DISTINCT fs.ps_partkey) AS total_parts,
    SUM(fs.adjusted_availqty) AS sum_avail_qty,
    AVG(fs.avg_discount) AS average_discount,
    MAX(fs.total_cost) AS max_cost_per_part
FROM FinalSelection fs
GROUP BY fs.s_name
HAVING COUNT(DISTINCT fs.ps_partkey) > 10
ORDER BY sum_avail_qty DESC;
