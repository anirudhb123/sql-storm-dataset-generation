WITH RECURSIVE Supplier_CTE AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        CAST(s.s_name AS varchar(100)) AS supplier_name,
        0 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        CAST(CONCAT(sct.supplier_name, ' -> ', s.s_name) AS varchar(100)),
        level + 1
    FROM 
        supplier s
    JOIN 
        Supplier_CTE sct ON s.s_nationkey = sct.s_nationkey
    WHERE 
        level < 3
),
Ranked_Orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
Part_Supplier_Stats AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    r.r_name, 
    SUM(ros.o_totalprice) AS total_order_value,
    p.p_name,
    ps.unique_suppliers,
    ps.total_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS total_customers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    Ranked_Orders ros ON o.o_orderkey = ros.o_orderkey
JOIN 
    Part_Supplier_Stats ps ON l.l_partkey = ps.p_partkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    ros.price_rank <= 5 
    AND ps.total_supply_cost IS NOT NULL
GROUP BY 
    r.r_name, p.p_name, ps.unique_suppliers, ps.total_supply_cost
ORDER BY 
    total_order_value DESC
LIMIT 10;
