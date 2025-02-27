WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_shippriority,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 5000
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        c.c_acctbal,
        COALESCE(n.n_name, 'Unknown') AS nation_name
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    cd.c_custkey,
    cd.c_name,
    cd.nation_name,
    o.o_orderkey,
    o.o_totalprice,
    o.o_orderdate,
    sp.p_name,
    sp.ps_availqty,
    sp.ps_supplycost,
    o.o_shippriority,
    CASE 
        WHEN o.o_orderstatus = 'O' THEN 'Completed'
        ELSE 'Pending'
    END AS order_status,
    ROW_NUMBER() OVER (PARTITION BY cd.c_custkey ORDER BY o.o_orderdate DESC) AS recent_order_rank
FROM 
    CustomerDetails cd
JOIN 
    RankedOrders o ON cd.c_custkey = o.o_orderkey
LEFT JOIN 
    SupplierParts sp ON o.o_orderkey = sp.ps_partkey
WHERE 
    cd.c_acctbal IS NOT NULL 
    AND (cd.c_acctbal > 3000 OR cd.c_name LIKE '%Inc%')
ORDER BY 
    cd.c_name, o.o_orderdate DESC;
