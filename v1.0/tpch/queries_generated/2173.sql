WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
),
FrequentCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
        LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, 
        c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
),
PriceDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    s.s_name AS supplier_name,
    fs.c_name AS frequent_customer,
    fs.order_count AS customer_order_count,
    COALESCE(pd.total_price, 0) AS total_order_value,
    CASE 
        WHEN pd.total_price IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM 
    SupplierStats s
    FULL OUTER JOIN FrequentCustomers fs ON fs.order_count > 0
    LEFT JOIN PriceDetails pd ON pd.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'O'
    )
WHERE 
    s.total_cost > 1000
ORDER BY 
    supplier_name, 
    frequent_customer;
