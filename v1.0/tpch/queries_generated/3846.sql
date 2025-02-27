WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 

HighVolumeOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2022-01-01' AND l.l_shipdate < '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), 

CustomerSupplier AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        c.c_acctbal,
        COALESCE(st.total_available, 0) AS total_available_from_suppliers,
        COUNT(DISTINCT st.s_suppkey) AS num_suppliers
    FROM 
        customer c
    LEFT JOIN 
        HighVolumeOrders hvo ON c.c_custkey = hvo.o_custkey
    LEFT JOIN 
        SupplierStats st ON st.s_suppkey IN (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
            WHERE l.l_orderkey = hvo.o_orderkey
        )
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
)

SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.c_acctbal,
    cs.total_available_from_suppliers,
    cs.num_suppliers,
    CASE 
        WHEN cs.total_available_from_suppliers > 5000 THEN 'High Supply'
        WHEN cs.total_available_from_suppliers BETWEEN 2000 AND 5000 THEN 'Medium Supply'
        ELSE 'Low Supply'
    END AS supply_status
FROM 
    CustomerSupplier cs
WHERE 
    cs.num_suppliers > 1
ORDER BY 
    cs.c_acctbal DESC, cs.num_suppliers ASC;

