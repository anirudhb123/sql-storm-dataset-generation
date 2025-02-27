WITH UserPostMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COALESCE(SUM(v.BountyAmount), 0) DESC) AS BountyRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Bounty start and close votes
    GROUP BY u.Id, u.DisplayName
), PostsHistoryInfo AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(ph.Id) AS EditCount,
        STRING_AGG(DISTINCT CAST(ph.Comment AS varchar), '; ') AS EditComments
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY ph.PostId
), PopularTags AS (
    SELECT 
        t.Id,
        t.TagName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.Id, t.TagName
    HAVING COUNT(DISTINCT p.Id) > 5 -- Only consider tags used in more than 5 posts
), CombinedMetrics AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        up.PostCount,
        up.QuestionCount,
        up.AnswerCount,
        up.TotalBounty,
        up.BountyRank,
        ph.FirstEditDate,
        ph.LastEditDate,
        ph.EditCount,
        ph.EditComments,
        pt.TagName,
        pt.TotalViews AS TagTotalViews,
        pt.PostCount AS TagPostCount,
        ROW_NUMBER() OVER (PARTITION BY up.UserId ORDER BY pt.TotalViews DESC) AS TagRank
    FROM UserPostMetrics up
    LEFT JOIN PostsHistoryInfo ph ON up.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ph.PostId)
    LEFT JOIN PopularTags pt ON pt.TotalViews >= 1000 -- Include tags with at least 1000 views
)
SELECT 
    cm.UserId,
    cm.DisplayName,
    cm.PostCount,
    cm.QuestionCount,
    cm.AnswerCount,
    cm.TotalBounty,
    cm.BountyRank,
    cm.FirstEditDate,
    cm.LastEditDate,
    cm.EditCount,
    cm.EditComments,
    cm.TagName,
    cm.TagTotalViews,
    cm.TagPostCount,
    CASE 
        WHEN cm.TagRank IS NULL THEN 'No Popular Tags'
        ELSE 'Has Popular Tags'
    END AS TagStatus
FROM CombinedMetrics cm
WHERE cm.BountyRank <= 10 OR cm.TagRank <= 5 -- Top 10 bounty users or top 5 users with popular tags
ORDER BY cm.TotalBounty DESC, cm.TagTotalViews DESC 
LIMIT 100;
