WITH CTE_Supplier_Summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        AVG(s.s_acctbal) AS avg_account_balance,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
        INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CTE_Large_Orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_quantity) OVER (PARTITION BY o.o_orderkey) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
        INNER JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'P')
),
Region_Nation AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        COUNT(n.n_nationkey) AS nation_count
    FROM 
        nation n
        JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name IS NOT NULL
    GROUP BY 
        n.n_nationkey, r.r_regionkey
)

SELECT 
    r.r_name,
    SUM(ss.total_cost) AS total_supplier_cost,
    COUNT(DISTINCT lo.o_orderkey) AS order_count,
    MAX(ss.avg_account_balance) AS max_account_balance,
    MAX(CASE WHEN rn.nation_count IS NULL THEN 'No Nations' ELSE 'Has Nations' END) AS nation_status
FROM 
    CTE_Supplier_Summary ss
    FULL OUTER JOIN CTE_Large_Orders lo ON ss.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey IN (
                SELECT 
                    p.p_partkey 
                FROM 
                    part p 
                WHERE 
                    p.p_size > 10
            )
        LIMIT 1
    )
    JOIN Region_Nation rn ON rn.n_nationkey = (
        SELECT 
            n.n_nationkey 
        FROM 
            nation n 
        WHERE 
            n.n_regionkey = (
                SELECT 
                    r.r_regionkey 
                FROM 
                    region r 
                WHERE 
                    r.r_name LIKE '%North%'
                LIMIT 1
            )
        LIMIT 1
    )
GROUP BY 
    r.r_name
HAVING 
    MAX(ss.total_cost) IS NOT NULL AND 
    COUNT(DISTINCT lo.o_orderkey) > 0
ORDER BY 
    total_supplier_cost DESC;
