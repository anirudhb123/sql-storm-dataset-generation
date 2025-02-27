WITH RECURSIVE CTE_OrderValue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        CTE_OrderValue cte ON cte.o_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate = DATE_ADD(cte.o_orderdate, INTERVAL 1 DAY)
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierPart AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
NationRanking AS (
    SELECT 
        n.n_name,
        RANK() OVER (ORDER BY SUM(s.s_acctbal) DESC) AS nation_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Completed'
            WHEN o.o_orderstatus = 'P' THEN 'Pending'
            ELSE 'Unknown'
        END AS order_status_desc,
        VALUE.total_value,
        n.n_name AS nation_name
    FROM 
        orders o
    LEFT JOIN 
        CTE_OrderValue VALUE ON o.o_orderkey = VALUE.o_orderkey
    LEFT JOIN 
        customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        supplier s ON c.c_nationkey = s.s_nationkey
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    os.o_orderkey,
    os.order_status_desc,
    os.total_value,
    sr.s_supplycost,
    nr.nation_rank
FROM 
    OrderSummary os
LEFT JOIN 
    SupplierPart sr ON os.o_orderkey = sr.s_suppkey
LEFT JOIN 
    NationRanking nr ON os.nation_name = nr.n_name
WHERE 
    os.total_value > (SELECT AVG(total_value) FROM OrderSummary)
ORDER BY 
    os.total_value DESC, nr.nation_rank;
