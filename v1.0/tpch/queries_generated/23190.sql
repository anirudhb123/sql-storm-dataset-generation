WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(DAY, -30, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        COALESCE(NULLIF(p.p_retailprice, 0), 1) AS adjusted_price
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size IS NOT NULL
),
FinalResult AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        po.p_partkey,
        po.p_name,
        CONCAT(CAST(rs.s_acctbal AS VARCHAR), ' - ', CASE WHEN rs.s_acctbal IS NULL THEN 'No Balance' ELSE 'Has Balance' END) AS account_info,
        CASE 
            WHEN ro.order_rank IS NOT NULL THEN ro.total_revenue
            ELSE (SELECT SUM(total_revenue) FROM RecentOrders)
        END AS total_order_revenue
    FROM 
        RankedSuppliers rs
    FULL OUTER JOIN 
        PartSupplierInfo po ON rs.s_suppkey = po.p_partkey
    LEFT JOIN 
        RecentOrders ro ON ro.o_orderstatus = 'O'
    WHERE 
        rs.supp_rank <= 5 OR po.ps_availqty IS NULL
    ORDER BY 
        rs.s_acctbal DESC NULLS LAST,
        po.p_name
)
SELECT * FROM FinalResult
WHERE 
    COALESCE(account_info, 'No Info') LIKE '%Has Balance%'
    AND total_order_revenue > 1000
UNION ALL
SELECT 
    NULL AS s_suppkey,
    'Aggregate' AS s_name,
    NULL AS p_partkey,
    NULL AS p_name,
    NULL AS account_info,
    SUM(total_order_revenue) FROM FinalResult;
