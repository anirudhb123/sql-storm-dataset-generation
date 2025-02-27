WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) as total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
    GROUP BY c.c_custkey, c.c_name
), ProductSuppliers AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty,
        p.p_name,
        ps.ps_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 50
), SalesAnalysis AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        li.l_quantity,
        li.l_discount,
        li.l_extendedprice,
        (li.l_extendedprice * (1 - li.l_discount)) AS net_price
    FROM lineitem li
    WHERE li.l_returnflag = 'N'
), SignificantSales AS (
    SELECT 
        sa.l_orderkey,
        COUNT(sa.l_partkey) AS number_of_parts,
        SUM(sa.net_price) AS total_sales
    FROM SalesAnalysis sa
    GROUP BY sa.l_orderkey
    HAVING SUM(sa.net_price) > 10000
), NotableOrders AS (
    SELECT 
        so.l_orderkey, 
        so.total_sales,
        CASE 
            WHEN so.number_of_parts > 5 THEN 'Bulk Order'
            ELSE 'Standard Order'
        END AS order_type
    FROM SignificantSales so
), CustomerRankings AS (
    SELECT 
        hc.c_custkey,
        hc.c_name,
        RANK() OVER (ORDER BY hc.total_spent DESC) AS customer_rank
    FROM HighValueCustomers hc
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT os.l_orderkey) AS total_orders,
    SUM(os.total_sales) AS overall_sales,
    ARRAY_AGG(DISTINCT ps.p_name) AS product_names,
    cs.customer_rank
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN ProductSuppliers ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem li ON ps.ps_partkey = li.l_partkey
LEFT JOIN NotableOrders os ON li.l_orderkey = os.l_orderkey
JOIN CustomerRankings cs ON cs.c_custkey = li.l_orderkey % 100  
WHERE s.s_acctbal IS NOT NULL
GROUP BY n.n_name, cs.customer_rank
HAVING COUNT(DISTINCT os.l_orderkey) > 0 OR SUM(os.total_sales) > 5000
ORDER BY overall_sales DESC NULLS LAST;