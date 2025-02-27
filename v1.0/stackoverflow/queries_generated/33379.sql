WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
),
PostVoteAggregates AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount
    FROM Votes v
    GROUP BY v.PostId
),
TagAnalytics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    pva.UpvoteCount,
    pva.DownvoteCount,
    ta.TagName,
    ta.PostCount,
    ta.TotalViews,
    ub.TotalBadges,
    ub.BadgeNames,
    u.DisplayName
FROM RankedPosts rp
LEFT JOIN PostVoteAggregates pva ON rp.PostId = pva.PostId
LEFT JOIN Tags ta ON ta.TagName IN (SELECT UNNEST(STRING_TO_ARRAY(rp.Tags, '<tag_delimiter>'))) -- Assuming a delimiter
LEFT JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
WHERE rp.UserRank <= 3 -- Top 3 posts by score per user
ORDER BY rp.CreationDate DESC, rp.Score DESC
FETCH FIRST 10 ROWS ONLY;
This query constructs various CTEs for summarizing data across different dimensions (posts, votes, tags, and user badges), aggregating and filtering the results to return the top posts. It uses various SQL constructs such as window functions, outer joins, and string manipulations to ensure a comprehensive performance benchmark across the Stack Overflow schema. Adjust `<tag_delimiter>` to specify the method for separating tags based on your schema design.
