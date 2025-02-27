WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
ActiveCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000.00
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        COUNT(o.o_orderkey) > 0
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_shipdate,
        l.l_returnflag,
        l.l_linestatus,
        CASE 
            WHEN l.l_discount > 0.10 THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE l.l_extendedprice 
        END AS discounted_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' AND 
        l.l_shipdate < CURRENT_DATE
),
PartSupplierAggregation AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
ComplexJoin AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(sub.total_availqty, 0) AS total_available,
        COALESCE(sub.avg_supplycost, 0) AS avg_cost,
        rs.rnk AS supplier_rank,
        alc.order_count
    FROM 
        part p
    LEFT JOIN 
        PartSupplierAggregation sub ON p.p_partkey = sub.ps_partkey
    LEFT JOIN 
        RankedSuppliers rs ON rs.s_suppkey = (
            SELECT MIN(s.s_suppkey)
            FROM supplier s
            WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey IS NOT NULL)
        )
    LEFT JOIN 
        ActiveCustomers alc ON alc.c_acctbal > p.p_retailprice
    WHERE 
        p.p_retailprice IS NOT NULL AND 
        p.p_size BETWEEN 10 AND 50
)
SELECT 
    DISTINCT p.p_partkey,
    p.p_name,
    p.total_available,
    p.avg_cost,
    p.supplier_rank,
    p.order_count,
    CASE 
        WHEN p.total_available > 500 THEN 'High Availability'
        WHEN p.total_available BETWEEN 200 AND 500 THEN 'Medium Availability'
        ELSE 'Low Availability'
    END AS availability_status
FROM 
    ComplexJoin p
WHERE 
    p.supplier_rank IS NOT NULL
ORDER BY 
    p.total_available DESC, 
    p.p_name;
