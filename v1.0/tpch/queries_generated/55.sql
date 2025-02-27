WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2024-01-01'
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        COUNT(ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
nations AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    no.n_name,
    no.region_name,
    SUM(no.total_account_balance) AS total_balance,
    COUNT(DISTINCT so.o_orderkey) AS total_orders,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_acctbal, ')'), '; ') AS supplier_details
FROM 
    nations no
LEFT JOIN 
    supplier_details sd ON no.n_nationkey = sd.s_nationkey
LEFT JOIN 
    lineitem l ON l.l_suppkey = sd.s_suppkey
LEFT JOIN 
    ranked_orders so ON l.l_orderkey = so.o_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
GROUP BY 
    no.n_name, no.region_name
HAVING 
    total_orders > 10 AND 
    total_balance IS NOT NULL
ORDER BY 
    total_balance DESC, no.n_name;
