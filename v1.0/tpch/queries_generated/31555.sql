WITH RECURSIVE TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        total_cost > 10000
), 

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 

SupplierRankings AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (ORDER BY total_cost DESC) AS rank
    FROM 
        TopSuppliers s
)

SELECT 
    co.c_name,
    co.order_count,
    co.total_spent,
    sr.s_name AS top_supplier,
    sr.rank
FROM 
    CustomerOrders co
LEFT JOIN 
    SupplierRankings sr ON sr.s_suppkey IN (
      SELECT ps.ps_suppkey 
      FROM partsupp ps 
      WHERE ps.ps_partkey IN (
          SELECT p.p_partkey 
          FROM part p 
          WHERE p.p_retailprice > 50
      )
    )
WHERE 
    co.total_spent IS NOT NULL
ORDER BY 
    co.total_spent DESC
LIMIT 10;
