WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.UpVotes,
        u.DownVotes,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL)
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        STRING_AGG(DISTINCT p.Title, '; ') AS SampleTitles
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, '><')::int[])
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        p.Id, p.Title, ph.Comment
    HAVING 
        COUNT(ph.Id) > 1
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.ReputationRank,
    ARRAY_AGG(DISTINCT pt.TagName) AS PopularTags,
    ub.TotalBadges,
    ub.HighestBadgeClass,
    COUNT(DISTINCT cp.PostId) AS ClosedPostCount,
    SUM(CASE WHEN cp.LastCloseDate > NOW() - INTERVAL '1 month' THEN 1 ELSE 0 END) AS RecentClosedPosts,
    STRING_AGG(DISTINCT pp.SampleTitles, '| ') AS SamplePostTitles
FROM 
    UserReputation ur
LEFT JOIN 
    UserBadges ub ON ur.UserId = ub.UserId
LEFT JOIN 
    PopularTags pp ON pp.PostCount >= 10 -- Join on popular tags from the previous CTE
LEFT JOIN 
    ClosedPosts cp ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId)
WHERE 
    ur.ReputationRank <= 100 -- Top 100 users by reputation
GROUP BY 
    ur.UserId, ur.DisplayName, ur.Reputation, ur.ReputationRank, ub.TotalBadges, ub.HighestBadgeClass
ORDER BY 
    ur.Reputation DESC;
This complex SQL query performs the following operations:

1. **Common Table Expressions (CTEs)**:
   - `UserReputation`: Calculates user reputation metrics, filtering users with above-average reputation and ranking them.
   - `PopularTags`: Aggregates tags with more than ten associated posts, gathering sample post titles.
   - `ClosedPosts`: Collects data regarding posts that have been closed multiple times, including their close reasons and dates.
   - `UserBadges`: Summarizes badge counts and highest badge class for users.

2. **Main SELECT Statement**:
   - Joins the CTEs to produce a comprehensive result set that includes users' `DisplayName`, `Reputation`, and the array of their popular tags, as well as badge information and closed post statistics.

3. **Calculations**:
   - Uses aggregation functions, window functions, and conditional aggregation to produce various metrics.

4. **String Handling**:
   - Utilizes `STRING_AGG` for concatenating tags and sample titles.

5. **UNUSUAL LOGIC**:
   - Incorporates handling for obscure cases such as closed posts within the last month.

This query covers a wide range of SQL features and presents a nuanced view of the data within the Stack Overflow schema.
