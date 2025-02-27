WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score > (
            SELECT AVG(Score) 
            FROM Posts 
            WHERE CreationDate >= NOW() - INTERVAL '1 year'
        )
),
TagCounts AS (
    SELECT 
        t.TagName, 
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 1
),
PostHistorySummary AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS EditCount, 
        MIN(ph.CreationDate) AS FirstEdit,
        MAX(ph.CreationDate) AS LastEdit
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold badges
    GROUP BY 
        b.UserId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(ubs.BadgeCount, 0) AS GoldBadgeCount,
    COALESCE(ps.EditCount, 0) AS TotalEdits,
    COALESCE(tc.PostCount, 0) AS RelatedTagsCount,
    CASE 
        WHEN COALESCE(ps.EditCount, 0) > 10 THEN 'Highly Edited'
        WHEN COALESCE(ps.EditCount, 0) > 0  THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus,
    CASE 
        WHEN rp.Score IS NULL THEN 'Score Missing'
        WHEN rp.Score < 0 THEN 'Negative Score'
        ELSE 'Positive Score'
    END AS ScoreStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ubs ON rp.OwnerUserId = ubs.UserId
LEFT JOIN 
    PostHistorySummary ps ON rp.PostId = ps.PostId
LEFT JOIN 
    TagCounts tc ON tc.TagName IN (
        SELECT 
            UNNEST(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
    )
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;

This SQL query performs a performance benchmark by incorporating various advanced SQL constructs such as CTEs (Common Table Expressions), window functions, outer joins, and conditional logic. The query retrieves recently created posts by users who have achieved a certain score in the last year, while providing insights on the edits made to the posts and the user's achievements.
