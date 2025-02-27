WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        AVG(COALESCE(1.0 * LENGTH(p.Body), 0)) AS AverageBodyLength,
        p.CreationDate,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
        LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
AggregatedStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(CommentCount) AS AvgCommentsPerPost,
        AVG(UpVoteCount) AS AvgUpVotesPerPost,
        AVG(DownVoteCount) AS AvgDownVotesPerPost,
        AVG(AverageBodyLength) AS AvgBodyLength,
        AVG(BadgeCount) AS AvgBadgesPerOwner
    FROM 
        PostStats
)
SELECT 
    * 
FROM 
    AggregatedStats;
