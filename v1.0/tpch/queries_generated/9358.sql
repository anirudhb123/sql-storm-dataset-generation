WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS total_price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
TopPriceOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice
    FROM 
        RankedOrders r
    WHERE 
        r.total_price_rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
FrequentCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        co.order_count,
        RANK() OVER (ORDER BY co.total_spent DESC) AS spending_rank
    FROM 
        CustomerOrders co
    WHERE 
        co.order_count > 10
)
SELECT 
    f.c_name,
    f.total_spent,
    f.order_count,
    t.o_orderkey,
    t.o_orderdate,
    t.o_totalprice
FROM 
    FrequentCustomers f
JOIN 
    TopPriceOrders t ON f.order_count = (SELECT MAX(order_count) FROM CustomerOrders co WHERE co.c_custkey = f.c_custkey)
ORDER BY 
    f.total_spent DESC,
    t.o_totalprice DESC;
