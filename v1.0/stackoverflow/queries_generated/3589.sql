WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountySpent,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.UserId, 
    u.DisplayName, 
    u.Reputation, 
    u.TotalBountySpent,
    u.UpvoteCount,
    u.DownvoteCount,
    COALESCE(p.PostId, -1) AS LatestPostId,
    COALESCE(p.Title, 'No Posts') AS LatestPostTitle,
    COALESCE(p.CreationDate, '1970-01-01') AS LatestPostDate,
    COALESCE(p.CommentCount, 0) AS LatestPostComments,
    COALESCE(p.HasAcceptedAnswer, 0) AS LatestPostHasAcceptedAnswer
FROM 
    UserActivity u
LEFT JOIN 
    RankedPosts p ON u.UserId = p.OwnerUserId AND p.PostRank = 1
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC, 
    LatestPostDate DESC
LIMIT 50;
