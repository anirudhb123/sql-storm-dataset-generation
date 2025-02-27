WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND o.o_totalprice > (
            SELECT AVG(o2.o_totalprice) 
            FROM orders o2 
            WHERE o2.o_orderdate < CURRENT_DATE
        )
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey
),
CustomerAnalysis AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_mktsegment = 'BUILDING' 
        AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
    GROUP BY 
        c.c_custkey
),
FinalResults AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ca.order_count,
        ca.total_spent,
        COALESCE(MAX(r.order_rank), 0) AS last_order_rank,
        si.total_supply_cost
    FROM 
        customer c
    LEFT JOIN CustomerAnalysis ca ON c.c_custkey = ca.c_custkey
    LEFT JOIN RankedOrders r ON r.o_orderkey = (
        SELECT TOP 1 o_orderkey 
        FROM orders 
        WHERE o_custkey = c.c_custkey 
        ORDER BY o_orderdate DESC
    )
    LEFT JOIN SupplierInfo si ON si.s_suppkey = (
        SELECT TOP 1 ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE l.l_orderkey IN (
            SELECT o.o_orderkey 
            FROM orders o 
            WHERE o.o_custkey = c.c_custkey
        ) 
        ORDER BY ps.ps_supplycost DESC
    )
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        SUM(CASE WHEN ca.order_count > 0 THEN 1 ELSE 0 END) > 1 
        OR SUM(si.total_supply_cost) IS NOT NULL
)
SELECT 
    f.c_custkey, 
    f.c_name, 
    f.c_acctbal, 
    f.order_count, 
    f.total_spent,
    f.last_order_rank,
    CASE
        WHEN f.total_supply_cost IS NOT NULL THEN 'Valid Supplier'
        ELSE 'Unknown Supplier'
    END AS supplier_status
FROM 
    FinalResults f
WHERE 
    f.total_spent > (
        SELECT AVG(total_spent) 
        FROM FinalResults
    )
ORDER BY 
    f.total_spent DESC, 
    f.order_count ASC;
