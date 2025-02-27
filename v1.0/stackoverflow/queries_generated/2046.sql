WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) / 3600 AS AgeInHours,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(b.Class = 1)::int AS GoldBadges,
        SUM(b.Class = 2)::int AS SilverBadges,
        SUM(b.Class = 3)::int AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.AnswerCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.AgeInHours,
    ur.DisplayName,
    ur.Reputation,
    ur.TotalPosts,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges
FROM 
    PostStats ps
JOIN 
    UserReputation ur ON ps.OwnerUserId = ur.UserId
WHERE 
    ps.UserPostRank <= 3
ORDER BY 
    ps.AnswerCount DESC, ps.UpVotes - ps.DownVotes DESC
LIMIT 100;
