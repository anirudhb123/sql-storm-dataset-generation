
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    pd.total_supplycost AS supplier_cost,
    cs.total_spent AS customer_spending,
    RANK() OVER (ORDER BY pd.total_supplycost DESC) AS supplier_cost_rank,
    cs.last_order_date,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        ELSE 'Ordered'
    END AS order_status
FROM part p
LEFT JOIN SupplierDetails pd ON p.p_partkey = (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_partkey = p.p_partkey
    ORDER BY ps.ps_supplycost DESC
    FETCH FIRST 1 ROW ONLY
)
LEFT JOIN CustomerSales cs ON cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
WHERE p.p_retailprice BETWEEN 10 AND 100
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    pd.total_supplycost, 
    cs.total_spent, 
    cs.last_order_date
ORDER BY supplier_cost_rank, p.p_partkey;
