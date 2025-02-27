-- Performance benchmarking query for analyzing post activity and user reputation
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        UNNEST(STRING_TO_ARRAY(p.Tags, '<>')) AS Tag
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.VoteCount,
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    us.PostCount,
    us.TotalViews
FROM 
    PostStats ps
JOIN 
    Users us ON ps.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = us.UserId)
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC
LIMIT 100;
