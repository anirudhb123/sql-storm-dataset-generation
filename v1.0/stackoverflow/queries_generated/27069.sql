WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagUsageCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 5 -- Only tags used in more than 5 questions
),
RecentUpdates AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS UpdateDate,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10, 11) -- Edits and close reasons
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.Score,
        COALESCE(ROW_NUMBER() OVER (PARTITION BY rp.PostId ORDER BY ru.UpdateDate DESC), 0) AS RecentUpdateRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentUpdates ru ON rp.PostId = ru.PostId
)
SELECT 
    ps.Title,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.Score,
    p.UserDisplayName AS Owner,
    AVG(distinct (pt.TagUsageCount) OVER (PARTITION BY ps.PostId)) AS AverageTagUsage,
    COUNT(*) FILTER (WHERE pu.TagUsageCount > 5) AS PopularTagsCount,
    ps.RecentUpdateRank
FROM 
    PostStatistics ps
JOIN 
    Users p ON ps.OwnerUserId = p.Id
LEFT JOIN 
    PopularTags pu ON ps.PostId IN (SELECT pt.PostId FROM Posts pt WHERE pt.Tags LIKE '%' || pu.TagName || '%')
WHERE 
    ps.RecentUpdateRank = 1 -- Most recent edit only
GROUP BY 
    ps.Title, ps.ViewCount, ps.AnswerCount, ps.CommentCount, ps.Score, p.UserDisplayName, ps.RecentUpdateRank
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
