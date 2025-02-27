WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE cte ON p.ParentId = cte.Id
),

UserBadgeCount AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    post.Id AS PostId,
    post.Title,
    post.Score,
    user.DisplayName AS Owner,
    post.CreationDate,
    COALESCE(vote.UpVotes, 0) AS UpVotes,
    COALESCE(vote.DownVotes, 0) AS DownVotes,
    COALESCE(badge.GoldBadges, 0) AS UserGoldBadges,
    COALESCE(badge.SilverBadges, 0) AS UserSilverBadges,
    COALESCE(badge.BronzeBadges, 0) AS UserBronzeBadges,
    COUNT(DISTINCT com.Id) AS CommentCount,
    COUNT(DISTINCT ph.Id) AS HistoryRecordCount,
    ROW_NUMBER() OVER (PARTITION BY post.OwnerUserId ORDER BY post.Score DESC) AS Ranking
FROM 
    RecursivePostCTE post
LEFT JOIN 
    Users user ON post.OwnerUserId = user.Id
LEFT JOIN 
    PostVoteStats vote ON post.Id = vote.PostId
LEFT JOIN 
    UserBadgeCount badge ON user.Id = badge.UserId
LEFT JOIN 
    Comments com ON post.Id = com.PostId
LEFT JOIN 
    PostHistory ph ON post.Id = ph.PostId
WHERE 
    post.Score > 10
GROUP BY 
    post.Id, user.DisplayName, post.CreationDate, vote.UpVotes, vote.DownVotes, badge.GoldBadges, badge.SilverBadges, badge.BronzeBadges
ORDER BY 
    post.Score DESC;
