WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND 
        o.o_orderdate < DATE '2024-01-01'
),
CustomerTotal as (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        c.c_acctbal > 1000.00
    GROUP BY
        c.c_custkey
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_supplycost > 10.00
    GROUP BY 
        s.s_suppkey
)
SELECT 
    c.c_name,
    c.c_acctbal,
    COALESCE(ct.total_spent, 0) AS total_spent,
    sp.total_cost AS supplier_cost,
    (SELECT AVG(l.l_extendedprice) 
     FROM lineitem l 
     WHERE l.l_orderkey IN (SELECT o.o_orderkey 
                             FROM orders o 
                             WHERE o.o_custkey = c.c_custkey)) AS avg_lineitem_price,
    CASE 
        WHEN c.c_acctbal > 10000 THEN 'High Value'
        WHEN c.c_acctbal BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    customer c
LEFT JOIN 
    CustomerTotal ct ON c.c_custkey = ct.c_custkey
LEFT JOIN 
    SupplierPerformance sp ON sp.part_count > 0
WHERE 
    EXISTS (SELECT 1 
            FROM RankedOrders ro 
            WHERE ro.o_orderkey IN (SELECT o.o_orderkey 
                                    FROM orders o 
                                    WHERE o.o_custkey = c.c_custkey) AND 
                  ro.rn <= 5)
ORDER BY 
    c.c_name;
