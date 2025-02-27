WITH RECURSIVE PriceTrends AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        c.c_custkey, o.o_orderkey
),
CriticalSuppliers AS (
    SELECT 
        nt.n_name AS nation_name,
        SUM(pt.total_supplycost) AS critical_supplycost
    FROM 
        PriceTrends pt
    JOIN 
        nation nt ON pt.s_suppkey = nt.n_nationkey
    GROUP BY 
        nt.n_name
    HAVING 
        critical_supplycost > (SELECT AVG(total_supplycost) FROM PriceTrends)
)
SELECT 
    co.c_custkey,
    co.order_value,
    pt.total_supplycost,
    cs.nation_name,
    CASE 
        WHEN co.order_value IS NULL THEN 'No Orders'
        WHEN pt.total_supplycost IS NULL THEN 'No Supplies'
        ELSE 'Active'
    END AS status
FROM 
    CustomerOrders co
FULL OUTER JOIN 
    PriceTrends pt ON co.c_custkey = pt.s_suppkey
FULL OUTER JOIN 
    CriticalSuppliers cs ON cs.nation_name = (SELECT MAX(n.n_name) FROM nation n WHERE n.n_nationkey IS NOT NULL)
WHERE 
    (co.order_rank = 1 OR pt.rank = 1)
    AND (co.order_value IS NOT NULL OR pt.total_supplycost IS NOT NULL)
ORDER BY 
    co.c_custkey ASC, pt.total_supplycost DESC;
