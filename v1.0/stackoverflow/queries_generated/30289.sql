WITH RecursivePost AS (
    SELECT 
        Id,
        Title,
        OwnerUserId,
        CreationDate,
        AcceptedAnswerId,
        Score,
        ViewCount,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Starting with questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.Score,
        p.ViewCount,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePost rp ON p.ParentId = rp.Id
)
, UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        r.Level AS AnswerLevel,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        RecursivePost r
    JOIN 
        Posts p ON p.Id = r.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'  -- Only consider recent posts
    GROUP BY 
        p.Id, u.DisplayName, r.Level, p.CreationDate, p.ViewCount, p.Score
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerLevel,
    ps.CommentCount,
    ud.DisplayName AS TopUserWithGoldBadges,
    ud.Reputation AS TopUserReputation
FROM 
    PostStatistics ps
LEFT JOIN 
    UserDetails ud ON ud.GoldBadges = (SELECT MAX(GoldBadges) FROM UserDetails)
ORDER BY 
    ps.Score DESC,
    ps.CreationDate DESC
LIMIT 10;
