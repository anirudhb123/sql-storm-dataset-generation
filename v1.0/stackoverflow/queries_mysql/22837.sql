
WITH TagStats AS (
    SELECT 
        t.TagName,
        p.PostTypeId,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags AS t
    LEFT JOIN 
        Posts AS p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Comments AS c ON c.PostId = p.Id
    LEFT JOIN 
        Users AS u ON u.Id = p.OwnerUserId
    GROUP BY 
        t.TagName, p.PostTypeId
),
ClosedPostStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM 
        PostHistory AS ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
RankedPostStats AS (
    SELECT 
        ts.TagName,
        ts.PostTypeId,
        ts.PostCount,
        COALESCE(cps.CloseCount, 0) AS CloseCount,
        ts.CommentCount,
        ts.AvgUserReputation,
        @row_num := IF(@prev_tag = ts.TagName, @row_num + 1, 1) AS Rank,
        @prev_tag := ts.TagName
    FROM 
        TagStats AS ts,
        (SELECT @row_num := 0, @prev_tag := '') AS vars
    LEFT JOIN 
        ClosedPostStats AS cps ON ts.PostCount = cps.CloseCount
)
SELECT 
    r.TagName,
    r.PostTypeId,
    r.PostCount,
    r.CloseCount,
    r.CommentCount,
    r.AvgUserReputation,
    CASE 
        WHEN r.CloseCount > 0 THEN 'Contains Closed Posts' 
        ELSE 'No Closed Posts' 
    END AS ClosingStatus
FROM 
    RankedPostStats AS r
WHERE 
    r.Rank = 1
    AND (r.CloseCount > 0 OR r.CommentCount IS NOT NULL)
ORDER BY 
    r.AvgUserReputation DESC,
    r.PostCount DESC;
