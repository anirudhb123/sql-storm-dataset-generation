WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
), 
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_container,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice, p.p_container
    HAVING 
        total_supply_cost > (SELECT AVG(ps_supplycost) FROM partsupp)
), 
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS segment_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = c.c_mktsegment)
), 
OrdersWithPartDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS part_count,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        returned_quantity < (SELECT AVG(returned_quantity) FROM 
            (SELECT 
                SUM(CASE WHEN l2.l_returnflag = 'R' THEN l2.l_quantity ELSE 0 END) AS returned_quantity
             FROM 
                lineitem l2
             GROUP BY 
                l2.l_orderkey) AS temp)
)

SELECT 
    fc.c_custkey,
    fc.c_name,
    fc.c_acctbal,
    SUM(od.total_price) AS total_order_value,
    STRING_AGG(DISTINCT CONCAT_WS(' - ', pp.p_name, pp.p_container)) AS purchased_parts,
    COALESCE(MAX(ps.s_name), 'No Supplier') AS max_supplier
FROM 
    FilteredCustomers fc
LEFT JOIN 
    OrdersWithPartDetails od ON fc.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = od.o_orderkey)
LEFT JOIN 
    HighValueParts pp ON pp.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = od.o_orderkey)
LEFT JOIN 
    RankedSuppliers ps ON ps.s_nationkey = fc.c_nationkey AND ps.rnk = 1
GROUP BY 
    fc.c_custkey, fc.c_name, fc.c_acctbal
HAVING 
    (SUM(od.total_price) > (SELECT AVG(total_order_value) FROM 
        (SELECT SUM(total_price) AS total_order_value FROM OrdersWithPartDetails GROUP BY o_orderkey) AS avg_temp)) 
    OR (fc.c_acctbal IS NULL)
ORDER BY 
    total_order_value DESC;
