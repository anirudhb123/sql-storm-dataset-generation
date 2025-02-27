WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_clerk,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
),
CustomerSum AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplier_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
JoinResults AS (
    SELECT 
        c.c_name,
        c.c_acctbal,
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_total,
        COALESCE(sc.total_supplier_cost, 0) AS supplier_cost
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        (SELECT 
            l.l_orderkey,
            l.l_partkey,
            l.l_quantity,
            l.l_extendedprice,
            o.o_custkey
        FROM 
            lineitem l
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey
        WHERE 
            o.o_orderstatus = 'F') AS LineDetails ON LineDetails.o_custkey = c.c_custkey
    LEFT JOIN 
        SupplierCosts sc ON LineDetails.l_partkey = sc.ps_partkey
    GROUP BY 
        c.c_name, c.c_acctbal, r.r_name
)
SELECT 
    j.*, 
    CASE 
        WHEN j.customer_total > 0 THEN ROUND(j.customer_total / NULLIF(j.supplier_cost, 0), 2) 
        ELSE NULL 
    END AS profit_margin_ratio
FROM 
    JoinResults j
WHERE 
    j.customer_total > (SELECT AVG(total_spent) FROM CustomerSum) 
    OR j.supplier_cost IS NOT NULL
ORDER BY 
    j.customer_total DESC, j.c_acctbal ASC
LIMIT 10;
