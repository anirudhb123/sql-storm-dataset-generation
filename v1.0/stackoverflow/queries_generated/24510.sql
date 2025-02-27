WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.CreationDate,
        p.Title,
        p.Tags,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(vote.Value) AS AverageVoteValue
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN (
        SELECT 
            v.UserId,
            CASE 
                WHEN v.VoteTypeId = 2 THEN 1
                WHEN v.VoteTypeId = 3 THEN -1
                ELSE 0 
            END AS Value
        FROM 
            Votes v
    ) vote ON u.Id = vote.UserId
    GROUP BY 
        u.Id
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS Comments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
OverallActivity AS (
    SELECT 
        p.PostId,
        SUM(COALESCE(rc.CommentCount, 0)) AS TotalComments,
        COUNT(DISTINCT CASE WHEN b.UserId IS NOT NULL THEN b.UserId END) AS DistinctUsersWithBadges,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM 
        RankedPosts p
    LEFT JOIN 
        RecentComments rc ON p.PostId = rc.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId
    WHERE 
        p.Rank <= 10
    GROUP BY 
        p.PostId
)
SELECT 
    oa.PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    u.UserId,
    u.BadgeCount,
    u.TotalBounty,
    oa.TotalComments,
    oa.DistinctUsersWithBadges,
    oa.TotalVotes,
    CASE 
        WHEN u.AverageVoteValue IS NULL THEN 'No Votes Yet'
        ELSE CONCAT('Average Vote Value: ', ROUND(u.AverageVoteValue, 2))
    END AS AverageVoteComment
FROM 
    OverallActivity oa
JOIN 
    Posts p ON oa.PostId = p.Id
JOIN 
    UserStatistics u ON p.OwnerUserId = u.UserId
WHERE 
    p.ViewCount > 50 OR 
    (p.ViewCount > 10 AND u.BadgeCount > 1)
ORDER BY 
    p.Score DESC, p.CreationDate DESC;

This SQL query benchmarks the performance of retrieving recently active post statistics from a Stack Overflow-like database. It utilizes Common Table Expressions (CTEs) to organize the data into manageable segments:

1. **RankedPosts**: Retrieves posts from the last year, ranked by score and creation date.
2. **UserStatistics**: Calculates statistics for each user, including the count of badges, total bounties, and average vote value.
3. **RecentComments**: Aggregates comments by post and provides a count and concatenated string of comments.
4. **OverallActivity**: Combines data to provide total comments and distinct users with badges for each post.

Finally, it joins these CTEs together to generate a detailed view of active posts, including user statistics and additional filtering based on view count and badge possession. The query also contains NULL logic handling and string expressions designed to display average vote values conditionally.
