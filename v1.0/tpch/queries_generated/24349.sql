WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
    AND 
        p.p_retailprice > 100
),
TotalOrders AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    WHERE 
        o.o_orderstatus <> 'O'
    GROUP BY 
        o.o_custkey
),
NullHandling AS (
    SELECT 
        c.c_custkey,
        COALESCE(to.total_spent, 0) AS total_spent,
        CASE 
            WHEN to.total_spent IS NULL THEN 'Customer has not spent anything'
            ELSE 'Customer has some order history'
        END AS order_history_status
    FROM 
        customer c
    LEFT JOIN 
        TotalOrders to ON c.c_custkey = to.o_custkey
),
ActiveSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        n.n_name AS nation_name,
        rs.rank
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank = 1
    AND 
        n.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE 'A%')
)
SELECT 
    nh.c_custkey,
    nh.total_spent,
    nh.order_history_status,
    asup.s_name AS top_supplier,
    asup.nation_name 
FROM 
    NullHandling nh
LEFT JOIN 
    ActiveSuppliers asup ON nh.total_spent > 1000
WHERE 
    NOT EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.o_custkey = nh.c_custkey 
        AND o.o_orderkey IN (
            SELECT l.l_orderkey
            FROM lineitem l
            WHERE l.l_discount > 0.5
        )
    ) 
ORDER BY 
    nh.total_spent DESC 
FETCH FIRST 10 ROWS ONLY;
