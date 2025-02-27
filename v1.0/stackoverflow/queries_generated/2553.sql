WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS PostCount, 
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotesCount,
        SUM(p.DownVotes) AS DownvotesCount,
        AVG(u.Reputation) AS AverageReputation,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        substring(tags FROM 2 FOR length(tags) - 2) AS Tag, 
        COUNT(*) AS Count
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        Tag
    ORDER BY 
        Count DESC
    LIMIT 5
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(pc.UpvoteCount, 0) AS UpvoteCount,
        COALESCE(pc.DownvoteCount, 0) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPost
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownvoteCount
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) pc ON p.Id = pc.PostId
)
SELECT 
    ua.DisplayName, 
    ua.PostCount, 
    ua.UpvotesCount, 
    ua.DownvotesCount, 
    pt.Tag AS PopularTag,
    ps.Title AS RecentPostTitle,
    ps.CreationDate AS RecentPostDate
FROM 
    UserActivity ua
CROSS JOIN 
    PopularTags pt
JOIN 
    PostStatistics ps ON ua.UserId = ps.PostId
WHERE 
    ua.PostCount > 0 
    AND ps.RecentPost = 1 
    AND ua.AverageReputation IS NOT NULL
ORDER BY 
    ua.PostRank;
