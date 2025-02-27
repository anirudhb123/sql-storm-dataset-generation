-- Performance benchmarking query for StackOverflow schema

WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpvoteCount,
        SUM(v.VoteTypeId = 3) AS DownvoteCount,
        SUM(b.Class = 1) AS GoldBadgeCount, 
        SUM(b.Class = 2) AS SilverBadgeCount,
        SUM(b.Class = 3) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(v.CreationDate) AS LastVoteDate,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS HasAcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId
)
SELECT 
    u.UserId,
    u.Reputation,
    u.PostCount,
    u.CommentCount,
    u.UpvoteCount,
    u.DownvoteCount,
    u.GoldBadgeCount,
    u.SilverBadgeCount,
    u.BronzeBadgeCount,
    p.PostId,
    p.PostTypeId,
    p.CommentCount AS PostCommentCount,
    p.VoteCount AS PostVoteCount,
    p.LastVoteDate,
    p.HasAcceptedAnswer
FROM 
    UserStatistics u
JOIN 
    PostStatistics p ON u.UserId = p.PostId
ORDER BY 
    u.Reputation DESC, p.VoteCount DESC;
