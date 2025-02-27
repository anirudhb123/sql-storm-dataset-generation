WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 5
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        CASE 
            WHEN SUM(ps.ps_availqty) > 1000 THEN 'High'
            WHEN SUM(ps.ps_availqty) BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS supply_rating
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
OrderStatistics AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_income,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
FinalReport AS (
    SELECT 
        r.r_name,
        p.p_name,
        n.n_name,
        ss.s_name,
        os.last_order_date,
        os.net_income,
        hp.supply_rating
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        RankedSuppliers ss ON n.n_nationkey = ss.s_suppkey
    JOIN 
        HighValueParts hp ON ss.s_suppkey = hp.p_partkey
    JOIN 
        OrderStatistics os ON ss.s_suppkey = os.o_orderkey
    WHERE 
        ss.rn = 1 AND hp.total_cost > 10000
    ORDER BY 
        r.r_name, os.net_income DESC
)
SELECT 
    *
FROM 
    FinalReport
WHERE 
    EXISTS (
        SELECT 1
        FROM FilteredNations fn
        WHERE fn.n_nationkey = FinalReport.n.n_nationkey 
        AND fn.supplier_count > 10
    )
OR
    NOT EXISTS (
        SELECT 1
        FROM lineitem l
        WHERE l.l_shipdate IS NULL 
        AND l.l_returnflag = 'R'
    );
