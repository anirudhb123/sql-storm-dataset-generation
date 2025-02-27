WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_clerk,
        ROW_NUMBER() OVER (PARTITION BY o.o_clerk ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderAmounts AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
ProductDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    COALESCE(rd.o_orderkey, 0) AS order_key,
    cd.c_name AS customer_name,
    pd.p_name AS product_name,
    pd.avg_supply_cost,
    rd.o_totalprice,
    CASE 
        WHEN rd.rank IS NOT NULL THEN 'Top Order'
        ELSE 'Regular Order'
    END AS order_type
FROM RankedOrders rd
FULL OUTER JOIN CustomerOrderAmounts cd ON rd.o_orderkey = cd.c_custkey
FULL OUTER JOIN ProductDetails pd ON pd.p_partkey IN (
    SELECT lp.l_partkey
    FROM lineitem lp
    WHERE lp.l_orderkey = rd.o_orderkey
)
WHERE (cd.total_spent IS NOT NULL OR rd.o_orderkey IS NULL)
AND pd.avg_supply_cost IS NOT NULL
ORDER BY rd.o_totalprice DESC, cd.c_name;
