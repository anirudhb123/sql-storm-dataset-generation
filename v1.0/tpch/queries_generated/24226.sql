WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
), 
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_income
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01'
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
), 
CustomerSegments AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS orders_count,
        CASE 
            WHEN c.c_acctbal < 1000 THEN 'Low Value'
            WHEN c.c_acctbal BETWEEN 1000 AND 5000 THEN 'Medium Value'
            ELSE 'High Value'
        END AS value_segment
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.total_available,
    ps.avg_supply_cost,
    ds.o_orderkey,
    ds.o_totalprice,
    ds.net_income,
    cs.orders_count,
    cs.value_segment,
    CASE 
        WHEN cs.orders_count IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    COALESCE(rs.s_name, 'Unknown Supplier') AS supplier_name
FROM 
    PartStats ps
LEFT JOIN 
    OrderDetails ds ON ds.o_totalprice = ps.avg_supply_cost -- unusual join condition
LEFT JOIN 
    CustomerSegments cs ON cs.orders_count > 0 OR cs.value_segment = 'Low Value' -- bizarre segment logic
LEFT JOIN 
    RankedSuppliers rs ON rs.rnk = 1 AND rs.s_suppkey = (SELECT ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = ps.p_partkey LIMIT 1)
WHERE 
    ps.avg_supply_cost IS NOT NULL 
    AND (ds.net_income > 5000 OR ds.o_orderkey IS NULL) -- complicated predicate
ORDER BY 
    ps.p_partkey, ds.o_orderkey DESC NULLS LAST;
