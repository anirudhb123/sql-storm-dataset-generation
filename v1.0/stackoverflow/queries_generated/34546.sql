WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CAST(0 AS INT) AS Depth
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
    UNION ALL
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ur.Depth + 1
    FROM 
        Users u
    JOIN 
        UserReputationCTE ur ON u.Reputation > ur.Reputation
    WHERE 
        ur.Depth < 5 -- limit depth to avoid infinite recursion
),
PostInteractionStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount,
        COALESCE(SUM(v.VoteTypeId IN (6, 7)), 0) AS CloseReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ActivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.CloseReopenCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostInteractionStats ps ON p.Id = ps.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT ap.PostId) AS ActivePostCount,
    SUM(ap.Score) AS TotalScore,
    AVG(CASE WHEN ap.CommentCount > 0 THEN ap.CommentCount END) AS AvgCommentCount,
    AVG(CASE WHEN ap.UpVoteCount > 0 THEN ap.UpVoteCount END) AS AvgUpVoteCount,
    AVG(CASE WHEN ap.DownVoteCount > 0 THEN ap.DownVoteCount END) AS AvgDownVoteCount
FROM 
    Users u
LEFT JOIN 
    ActivePostStats ap ON u.Id = ap.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    b.Date >= NOW() - INTERVAL '6 months' AND b.Class = 1 -- Only Gold badges in the last 6 months
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT ap.PostId) > 5 -- Users with more than 5 active posts
ORDER BY 
    SUM(ap.Score) DESC
LIMIT 10;

