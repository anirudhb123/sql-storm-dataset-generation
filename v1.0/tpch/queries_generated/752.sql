WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) 
                        FROM supplier s2 
                        WHERE s2.s_nationkey = s.s_nationkey)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_extendedprice * (1 - l.l_discount) AS net_price,
        l.l_shipdate
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N' 
        AND l.l_shipdate >= DATE '2022-01-01'
),
CombinedData AS (
    SELECT 
        cs.c_name AS customer_name,
        ps.p_name AS part_name,
        COUNT(DISTINCT li.l_orderkey) AS order_count,
        SUM(li.net_price) AS total_net_price
    FROM 
        FilteredLineItems li
    JOIN 
        CustomerOrders cs ON li.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
    JOIN 
        part ps ON li.l_partkey = ps.p_partkey
    GROUP BY 
        cs.c_name, ps.p_name
)
SELECT 
    cd.customer_name,
    cd.part_name,
    cd.order_count,
    cd.total_net_price,
    rs.s_name AS top_supplier
FROM 
    CombinedData cd
LEFT JOIN 
    RankedSuppliers rs ON cd.part_name = (SELECT p.p_name 
                                            FROM part p 
                                            WHERE p.p_partkey = (SELECT ps.ps_partkey 
                                                                 FROM partsupp ps 
                                                                 WHERE ps.ps_suppkey = rs.s_suppkey 
                                                                 ORDER BY ps.ps_supplycost 
                                                                 LIMIT 1)
                                            LIMIT 1)
ORDER BY 
    cd.total_net_price DESC
LIMIT 10;
