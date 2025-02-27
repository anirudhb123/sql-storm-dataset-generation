WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_name, s.s_suppkey, n.n_regionkey
), TotalOrders AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, CURRENT_DATE) 
        AND o.o_orderstatus = 'O'
    GROUP BY 
        o.o_custkey
), CustomerSegmentStats AS (
    SELECT 
        c.c_mktsegment,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        AVG(coalesce(t.total_order_value, 0)) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        TotalOrders t ON c.c_custkey = t.o_custkey
    GROUP BY 
        c.c_mktsegment
    HAVING 
        COUNT(DISTINCT c.c_custkey) > 0
)
SELECT 
    cs.c_mktsegment,
    cs.customer_count,
    cs.avg_order_value,
    ss.s_name,
    ss.total_supply_cost
FROM 
    CustomerSegmentStats cs
LEFT JOIN 
    RankedSuppliers ss ON cs.c_mktsegment = (
      SELECT cm.c_mktsegment
      FROM customer cm
      WHERE cm.c_custkey IN 
          (SELECT t.o_custkey
           FROM orders t 
           WHERE t.o_orderstatus = 'O'
           GROUP BY t.o_custkey 
           HAVING SUM(t.o_totalprice) > 100000)
      LIMIT 1
    )
WHERE 
    ss.rank <= 5 OR ss.s_suppkey IS NULL
ORDER BY 
    cs.customer_count DESC, 
    cs.avg_order_value DESC;
