WITH RECURSIVE UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        1 AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        ur.Level + 1
    FROM 
        Users u
    INNER JOIN UserReputation ur ON u.Id = ur.UserId
    WHERE 
        ur.Level < 5 AND u.Reputation > 1000
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(a.AcceptedAnswerCount, 0) AS AcceptedAnswerCount,
        COALESCE(v.VoteCount, 0) AS UpVoteCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) pc ON p.Id = pc.PostId
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AcceptedAnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 -- Answer
        GROUP BY 
            ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 2 -- UpMod (Upvote)
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON p.OwnerUserId = b.UserId
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.AcceptedAnswerCount,
        ps.UpVoteCount,
        ps.BadgeCount,
        RANK() OVER (ORDER BY ps.UpVoteCount DESC, ps.CommentCount DESC) AS Rank
    FROM 
        PostStats ps
    WHERE 
        ps.CommentCount > 5
)
SELECT 
    t.Title,
    t.CommentCount,
    t.AcceptedAnswerCount,
    t.UpVoteCount,
    t.BadgeCount,
    ur.Reputation,
    t.Rank
FROM 
    TopPosts t
JOIN 
    Users u ON t.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
WHERE 
    ur.Level = 1 -- Only include the first level of reputation
ORDER BY 
    t.Rank;
