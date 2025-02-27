WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions.
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        ph.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBountyEarned
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9  -- BountyClose
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagUsageCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        PostLinks pl ON pl.RelatedPostId = p.Id
    GROUP BY 
        t.TagName
    ORDER BY 
        TagUsageCount DESC
    LIMIT 10
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    us.QuestionCount,
    us.AnswerCount,
    us.TotalBountyEarned,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.UserId = u.Id AND ph.PostHistoryTypeId = 10) AS ClosedPosts,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.UserId = u.Id AND ph.PostHistoryTypeId IN (11, 12)) AS ReopenedOrUndeletedPosts,
    (SELECT STRING_AGG(t.TagName, ', ') FROM PopularTags t) AS PopularTags
FROM 
    Users u
JOIN 
    UserStatistics us ON u.Id = us.UserId
WHERE 
    u.Reputation > 1000  -- Only users with a reputation greater than 1000.
ORDER BY 
    us.TotalBountyEarned DESC;
