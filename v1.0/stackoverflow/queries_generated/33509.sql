WITH RECURSIVE TagHierarchy AS (
    SELECT 
        Id, 
        TagName, 
        Count, 
        ExcerptPostId, 
        WikiPostId, 
        IsModeratorOnly, 
        IsRequired, 
        0 AS Level
    FROM 
        Tags
    WHERE 
        IsModeratorOnly = 0

    UNION ALL

    SELECT 
        t.Id, 
        t.TagName, 
        t.Count, 
        t.ExcerptPostId, 
        t.WikiPostId, 
        t.IsModeratorOnly, 
        t.IsRequired, 
        th.Level + 1
    FROM 
        Tags t
    JOIN 
        TagHierarchy th ON t.WikiPostId = th.Id
    WHERE 
        t.IsModeratorOnly = 0
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    um.UserId,
    um.DisplayName,
    COUNT(pm.PostId) AS TotalPosts,
    SUM(pm.CommentCount) AS TotalComments,
    SUM(pm.UpVoteCount) AS TotalUpVotes,
    SUM(pm.DownVoteCount) AS TotalDownVotes,
    u.TotalBadges,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    th.TagName,
    th.Level,
    (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = um.UserId AND ClosedDate IS NOT NULL) AS TotalClosedPosts
FROM 
    UserBadges u
JOIN 
    PostMetrics pm ON u.UserId = pm.OwnerUserId
JOIN 
    TagHierarchy th ON pm.PostId IN (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.Tags LIKE '%' || th.TagName || '%'
    )
GROUP BY 
    um.UserId, um.DisplayName, u.TotalBadges, u.GoldBadges, u.SilverBadges, u.BronzeBadges, th.TagName, th.Level
ORDER BY 
    TotalPosts DESC, TotalUpVotes DESC
LIMIT 100;
