WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COALESCE(bg.BadgeCount, 0) AS BadgeCount,
        u.UpVotes - u.DownVotes AS Score,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS BadgeCount 
        FROM Badges 
        GROUP BY UserId
    ) bg ON u.Id = bg.UserId
    WHERE 
        u.Reputation > 1000 OR u.LastAccessDate < NOW() - INTERVAL '1 year'
), 
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS Tag, 
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        Tag
    HAVING 
        COUNT(p.Id) > 10
), 
CloseReasonCounts AS (
    SELECT 
        history.PostId,
        COUNT(history.Id) AS CloseCount,
        MIN(history.CreationDate) AS FirstCloseDate
    FROM 
        PostHistory history
    WHERE 
        history.PostHistoryTypeId = 10
    GROUP BY 
        history.PostId
),
FinalResults AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        u.Reputation,
        pt.Tag,
        pr.Rank,
        COALESCE(cr.CloseCount, 0) AS ClosedPosts,
        COALESCE(cr.FirstCloseDate, '1970-01-01') AS FirstClosedDate
    FROM 
        UserStatistics us
    JOIN 
        PopularTags pt ON us.Rank BETWEEN 1 AND 10
    LEFT JOIN 
        CloseReasonCounts cr ON cr.PostId IN (
            SELECT Id 
            FROM Posts 
            WHERE OwnerUserId = us.UserId
        )
    WHERE 
        us.BadgeCount > 1 AND pt.PostCount > 5
)
SELECT 
    fr.UserId,
    fr.DisplayName,
    fr.Reputation,
    fr.Tag,
    fr.ClosedPosts,
    fr.FirstClosedDate,
    CASE 
        WHEN fr.ClosedPosts > 5 THEN 'Highly Engaged'
        WHEN fr.ClosedPosts BETWEEN 1 AND 5 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    FinalResults fr
WHERE 
    NOT EXISTS (
        SELECT 
            1 
        FROM Badges b 
        WHERE b.UserId = fr.UserId AND b.Class = 1
    )
ORDER BY 
    fr.Reputation DESC, fr.ClosedPosts ASC;
