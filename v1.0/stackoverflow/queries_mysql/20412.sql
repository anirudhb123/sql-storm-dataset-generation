
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        @row_number := @row_number + 1 AS ReputationRank,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    CROSS JOIN (SELECT @row_number := 0) r
    GROUP BY 
        u.Id, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 6 THEN 1 ELSE 0 END) AS CloseVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
    GROUP BY 
        p.Id, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.CloseVoteCount,
        @post_rank := IF(@current_user = ps.OwnerUserId, @post_rank + 1, 1) AS PostRank,
        @current_user := ps.OwnerUserId
    FROM 
        PostStats ps
    CROSS JOIN (SELECT @post_rank := 0, @current_user := NULL) r
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ur.ReputationRank,
    ur.BadgeCount,
    tp.PostId,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    tp.CloseVoteCount
FROM 
    UserReputation ur
LEFT JOIN 
    TopPosts tp ON ur.UserId = tp.OwnerUserId AND tp.PostRank = 1
WHERE 
    ur.Reputation IS NOT NULL
    AND (ur.Reputation > 100 OR ur.BadgeCount > 5)
ORDER BY 
    ur.Reputation DESC, tp.UpVoteCount DESC
LIMIT 10 OFFSET 5;
