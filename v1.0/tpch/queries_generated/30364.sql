WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.s_nationkey,
        sh.level + 1
    FROM 
        supplier sp
    JOIN 
        SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE 
        sp.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = sh.s_nationkey)
),
TotalOrderValues AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        o.o_orderstatus,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_orderdate
),
FilteredSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        region r ON s.s_nationkey = r.r_regionkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
)
SELECT 
    sh.s_suppkey,
    sh.s_name,
    COALESCE(fs.total_supply_cost, 0) AS supply_cost,
    tv.total_value,
    CASE 
        WHEN tv.o_orderstatus = 'O' THEN 'Open'
        ELSE 'Closed'
    END AS order_status,
    ROW_NUMBER() OVER (PARTITION BY sh.s_nationkey ORDER BY fs.total_supply_cost DESC) AS rank
FROM 
    SupplierHierarchy sh
LEFT JOIN 
    TotalOrderValues tv ON sh.s_suppkey = tv.o_orderkey
LEFT JOIN 
    FilteredSupplier fs ON sh.s_suppkey = fs.s_suppkey
WHERE 
    fs.total_supply_cost IS NULL OR fs.total_supply_cost > 50000
ORDER BY 
    rank, supply_cost DESC;
