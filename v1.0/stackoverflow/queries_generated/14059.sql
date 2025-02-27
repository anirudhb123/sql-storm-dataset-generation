WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '><')) AS t(TagName) ON TRUE
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.OwnerUserId = u.Id THEN 1 ELSE 0 END) AS PostsCount,
        SUM(CASE WHEN c.UserId = u.Id THEN 1 ELSE 0 END) AS CommentsCount,
        SUM(CASE WHEN v.UserId = u.Id THEN 1 ELSE 0 END) AS VotesCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    ps.PostId,
    ps.PostTypeId,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    us.UserId,
    us.Reputation,
    us.BadgeCount,
    us.PostsCount,
    us.CommentsCount,
    us.VotesCount,
    ps.Tags
FROM 
    PostStats ps
JOIN 
    Users us ON ps.OwnerUserId = us.Id
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC;
