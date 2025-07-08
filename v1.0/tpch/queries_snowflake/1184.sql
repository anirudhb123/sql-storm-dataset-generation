
WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL)
), 
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
), 
RankedCustomerOrders AS (
    SELECT 
        cust.c_custkey, 
        cust.c_name, 
        cust.o_orderkey, 
        cust.total_revenue,
        RANK() OVER (ORDER BY cust.total_revenue DESC) AS revenue_rank
    FROM 
        CustomerOrderDetails cust
)
SELECT 
    spd.s_name AS supplier_name, 
    p.p_name AS part_name, 
    COALESCE(ru.o_orderkey, 0) AS order_key,
    COALESCE(ru.total_revenue, 0) AS order_revenue,
    CASE 
        WHEN ru.revenue_rank IS NULL THEN 'No Order'
        ELSE 'Has Order'
    END AS order_status,
    spd.ps_availqty AS available_quantity,
    spd.ps_supplycost AS supply_cost
FROM 
    SupplierPartDetails spd
LEFT JOIN 
    RankedCustomerOrders ru ON spd.s_suppkey = (SELECT MAX(ps.ps_suppkey) 
                                                  FROM partsupp ps 
                                                  WHERE ps.ps_partkey = spd.p_partkey)
    AND ru.revenue_rank <= 10
LEFT JOIN 
    part p ON p.p_partkey = spd.p_partkey
ORDER BY 
    supplier_name, part_name;
