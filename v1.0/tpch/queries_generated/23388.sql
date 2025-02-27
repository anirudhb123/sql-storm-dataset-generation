WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
),
CountryAggregate AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
),
PartSupplierAvailability AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, ps.ps_availqty
),
TopPartSupply AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p_total_avail.avail_quantity,
        ROW_NUMBER() OVER (ORDER BY p_total_avail.avail_quantity DESC) AS rn
    FROM part p
    JOIN (
        SELECT 
            ps.ps_partkey,
            SUM(ps.ps_availqty) AS avail_quantity
        FROM partsupp ps
        GROUP BY ps.ps_partkey
    ) p_total_avail ON p.p_partkey = p_total_avail.ps_partkey
    WHERE p.p_retailprice > 50
)
SELECT 
    r.r_name,
    ca.total_customers,
    ca.total_sales,
    ps.p_name,
    ps.avail_quantity,
    CASE 
        WHEN ps.avail_quantity IS NULL THEN 'Not Available'
        ELSE 'Available'
    END AS availability_status,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice END) AS total_returned_value,
    (SELECT COUNT(*)
     FROM orders o2
     WHERE o2.o_orderstatus = 'F' AND o2.o_orderdate < CURRENT_DATE - INTERVAL '1 year') AS historical_fulfilled_orders
FROM region r
JOIN CountryAggregate ca ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name LIKE 'A%')
LEFT JOIN TopPartSupply ps ON ps.rn <= 5
LEFT JOIN lineitem l ON ps.p_partkey = l.l_partkey
GROUP BY r.r_name, ca.total_customers, ca.total_sales, ps.p_name, ps.avail_quantity
ORDER BY ca.total_sales DESC, availability_status;
