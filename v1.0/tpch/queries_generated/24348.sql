WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus <> 'F'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (
            SELECT AVG(o2.o_totalprice) 
            FROM orders o2 
            WHERE o2.o_orderstatus <> 'F'
        )
),
RecentLateDeliveries AS (
    SELECT 
        l.l_orderkey,
        DATEDIFF(l.l_receiptdate, l.l_shipdate) AS DelayInDays
    FROM 
        lineitem l
    WHERE 
        l.l_commitdate > l.l_shipdate
),
AggregatedData AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS ReturnedQuantity,
        COALESCE(SUM(CASE WHEN l.l_returnflag <> 'R' THEN l.l_quantity ELSE 0 END), 0) AS SoldQuantity,
        ROUND(AVG(ps.ps_supplycost), 2) AS AvgSupplyCost
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.s_name AS SupplierName,
    hv.c_name AS CustomerName,
    a.p_name AS ProductName,
    a.SoldQuantity,
    a.ReturnedQuantity,
    CASE 
        WHEN a.ReturnedQuantity > a.SoldQuantity * 0.1 THEN 'High Return'
        WHEN a.ReturnedQuantity < 1 THEN 'Low Return'
        ELSE 'Normal Return'
    END AS ReturnStatus,
    rd.DelayInDays AS DeliveryDelay
FROM 
    RankedSuppliers r
INNER JOIN 
    HighValueCustomers hv ON hv.TotalSpent > (SELECT AVG(TotalCost) FROM RankedSuppliers)
LEFT JOIN 
    AggregatedData a ON a.SoldQuantity > 0
LEFT JOIN 
    RecentLateDeliveries rd ON rd.l_orderkey IN (SELECT l_orderkey FROM lineitem WHERE l_suppkey = r.s_suppkey)
WHERE 
    r.rank = 1
ORDER BY 
    r.TotalCost DESC, 
    hv.TotalSpent DESC, 
    a.ReturnedQuantity DESC;
