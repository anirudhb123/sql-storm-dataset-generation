WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_shippriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, p.p_partkey, p.p_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c1.c_acctbal) FROM customer c1)
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 100000
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (
            SELECT AVG(total_cost) FROM (
                SELECT 
                    SUM(ps_supplycost * ps_availqty) AS total_cost
                FROM 
                    supplier s
                JOIN 
                    partsupp ps ON s.s_suppkey = ps.ps_suppkey
                GROUP BY 
                    s.s_suppkey
            ) AS costs
        )
),
FinalResult AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.o_shippriority,
        hp.c_custkey,
        hp.total_spent,
        ROW_NUMBER() OVER (PARTITION BY r.o_shippriority ORDER BY hp.total_spent DESC) AS priority_rank
    FROM 
        RankedOrders r
    LEFT JOIN 
        HighValueCustomers hp ON r.o_orderkey = (
            SELECT o_orderkey 
            FROM orders 
            WHERE o_custkey = hp.c_custkey 
            ORDER BY o_orderdate DESC 
            LIMIT 1
        )
    LEFT JOIN 
        TopSuppliers ts ON ts.s_suppkey = (
            SELECT ps_suppkey 
            FROM partsupp 
            WHERE ps_partkey IN (SELECT p_partkey FROM part WHERE p_name LIKE '%widget%') 
            ORDER BY ps_supplycost LIMIT 1
        )
    WHERE 
        r.rnk <= 10
)
SELECT 
    f.o_orderkey,
    f.o_orderdate,
    f.o_totalprice,
    f.o_shippriority,
    COALESCE(f.c_custkey, 0) AS customer_key,
    COALESCE(f.total_spent, 0) AS total_spent,
    CASE 
        WHEN f.priority_rank IS NULL THEN 'N/A' 
        ELSE CAST(f.priority_rank AS VARCHAR)
    END AS priority_rank_status
FROM 
    FinalResult f
ORDER BY 
    f.o_orderdate, f.total_spent DESC;