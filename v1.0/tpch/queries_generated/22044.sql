WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Balance'
            WHEN s.s_acctbal < 500.00 THEN 'Low Balance'
            ELSE 'Sufficient Balance'
        END AS AccountStatus,
        COUNT(ps.ps_partkey) AS TotalParts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS TotalSpent,
        MAX(o.o_orderdate) AS LastOrderDate
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS LineItemCount,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalLineItemPrice
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
CombinedInfo AS (
    SELECT 
        si.s_name,
        ci.c_name,
        ci.TotalSpent,
        li.LineItemCount,
        li.TotalLineItemPrice
    FROM 
        SupplierInfo si
    FULL OUTER JOIN 
        CustomerOrders ci ON si.TotalParts = (SELECT COUNT(*) FROM partsupp WHERE ps_suppkey = si.s_suppkey)
    FULL OUTER JOIN 
        LineItemStats li ON ci.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = li.l_orderkey)
    WHERE 
        si.AccountStatus = 'Low Balance' 
        OR (ci.TotalSpent = 0 AND li.LineItemCount IS NOT NULL)
)
SELECT 
    * 
FROM 
    CombinedInfo
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM nation n 
        WHERE n.n_nationkey IN (
            SELECT c.c_nationkey 
            FROM customer c 
            WHERE c.c_name LIKE '%XYZ%'
        ) 
        AND (n.n_comment IS NULL OR n.n_comment NOT LIKE '%suppressed%')
    )
ORDER BY 
    TotalSpent DESC, LineItemCount ASC NULLS LAST;
