WITH SupplierStats AS (
    SELECT 
        s_nationkey,
        COUNT(DISTINCT s_suppkey) AS total_suppliers,
        SUM(s_acctbal) AS total_balance
    FROM 
        supplier
    GROUP BY 
        s_nationkey
),
PartStats AS (
    SELECT 
        p_partkey,
        p_brand,
        SUM(ps_availqty) AS total_available,
        AVG(p_retailprice) AS avg_price
    FROM 
        part
    JOIN 
        partsupp ON p_partkey = ps_partkey
    GROUP BY 
        p_partkey, p_brand
),
OrderStats AS (
    SELECT 
        o_custkey,
        COUNT(o_orderkey) AS total_orders,
        SUM(o_totalprice) AS total_spent
    FROM 
        orders
    GROUP BY 
        o_custkey
),
RankedOrders AS (
    SELECT 
        o_custkey,
        total_orders,
        total_spent,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS order_rank
    FROM 
        OrderStats
)
SELECT 
    n.n_name,
    COALESCE(S.total_suppliers, 0) AS supplier_count,
    COALESCE(P.total_available, 0) AS total_part_availability,
    COALESCE(O.total_orders, 0) AS total_orders,
    O.total_spent,
    CASE 
        WHEN O.total_spent > 1000 THEN 'High Spender'
        WHEN O.total_spent BETWEEN 500 AND 1000 THEN 'Moderate Spender'
        ELSE 'Low Spender'
    END AS spending_category,
    ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY COALESCE(O.total_spent, 0) DESC) AS regional_rank
FROM 
    nation n
LEFT JOIN 
    SupplierStats S ON n.n_nationkey = S.s_nationkey
LEFT JOIN 
    PartStats P ON P.p_brand LIKE 'Brand%'
LEFT JOIN 
    RankedOrders O ON n.n_nationkey = (SELECT c_nationkey FROM customer WHERE c_custkey = O.o_custkey)
WHERE 
    n.r_name IS NOT NULL
ORDER BY 
    n.n_name, O.total_spent DESC;
