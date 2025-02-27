WITH RECURSIVE SalesCTE AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        1 AS depth
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
    
    UNION ALL

    SELECT
        sc.c_custkey,
        sc.c_name,
        SUM(o.o_totalprice) AS total_spent,
        sc.depth + 1
    FROM
        SalesCTE sc
    JOIN
        orders o ON sc.c_custkey = o.o_custkey
    WHERE
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY
        sc.c_custkey, sc.c_name, sc.depth
),
RankedCustomers AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM
        SalesCTE
)

SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    r.r_name AS region_name,
    c.c_name AS customer_name,
    c.c_acctbal AS customer_balance,
    CASE 
        WHEN c.c_acctbal IS NULL THEN 'No Account Balance'
        WHEN c.c_acctbal < 1000 THEN 'Low Balance'
        ELSE 'Stable Balance'
    END AS account_status
FROM 
    lineitem l
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedCustomers rc ON c.c_custkey = rc.c_custkey
WHERE 
    l.l_shipdate >= '2023-01-01' AND 
    (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY 
    s.s_name, p.p_name, r.r_name, c.c_name, c.c_acctbal, rc.rank
HAVING 
    total_orders > 10 AND 
    account_status <> 'No Account Balance'
ORDER BY 
    revenue DESC
LIMIT 100;
