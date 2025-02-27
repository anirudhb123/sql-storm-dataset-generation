WITH PerformanceBenchmark AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
)
SELECT 
    AVG(VoteCount) AS AvgVoteCount,
    AVG(CommentCount) AS AvgCommentCount,
    AVG(BadgeCount) AS AvgBadgeCount,
    AVG(HistoryCount) AS AvgHistoryCount
FROM 
    PerformanceBenchmark;
