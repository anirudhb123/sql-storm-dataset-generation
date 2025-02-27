
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderstatus IN ('O', 'F')
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
CustomerOrderAmounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.total_available, 0) AS available_quantity,
    COALESCE(s.avg_supplycost, 0) AS average_supply_cost,
    COALESCE(c.order_count, 0) AS total_orders,
    COALESCE(c.total_spent, 0) AS total_spent,
    COALESCE(
        (SELECT COUNT(DISTINCT li.l_orderkey) 
         FROM lineitem li 
         WHERE li.l_partkey = p.p_partkey AND li.l_shipdate > DATE '1998-10-01' - INTERVAL '30 days'), 
    0) AS ship_count_last_30_days,
    ROW_NUMBER() OVER (ORDER BY COALESCE(c.total_spent, 0) DESC) AS customer_spending_rank
FROM 
    part p
LEFT JOIN 
    SupplierStats s ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
LEFT JOIN 
    CustomerOrderAmounts c ON c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT lo.l_orderkey FROM lineitem lo WHERE lo.l_partkey = p.p_partkey))
WHERE 
    p.p_retailprice BETWEEN 10 AND 500
ORDER BY 
    available_quantity DESC, 
    total_spent DESC 
LIMIT 100;
