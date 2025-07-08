
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus = 'O')
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ro.o_totalprice) AS total_order_value,
        COUNT(ro.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        RankedOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
NationSupplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        LISTAGG(s.s_name, ', ') AS suppliers,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FilteredOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_totalprice,
        CASE 
            WHEN ro.o_totalprice IS NULL THEN 'Unknown'
            ELSE 'Known'
        END AS price_existence
    FROM 
        RankedOrders ro
    WHERE 
        EXISTS (SELECT 1 FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey AND l.l_discount > 0.05)
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.total_order_value,
    co.order_count,
    ns.n_name,
    ns.suppliers,
    ps.total_supplycost,
    CASE 
        WHEN ps.total_supplycost IS NULL THEN 'No Supply Info'
        ELSE 'Supply Info Present'
    END AS supply_info_status
FROM 
    CustomerOrders co
LEFT JOIN 
    NationSupplier ns ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA' LIMIT 1)
LEFT JOIN 
    PartSupplier ps ON ps.ps_partkey = (SELECT MIN(l.l_partkey) FROM lineitem l WHERE l.l_orderkey IN (SELECT ro.o_orderkey FROM RankedOrders ro WHERE ro.o_custkey = co.c_custkey))
WHERE 
    co.total_order_value > (SELECT AVG(total_order_value) FROM CustomerOrders WHERE order_count > 0)
ORDER BY 
    co.total_order_value DESC
LIMIT 10;
