WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL 
    
    SELECT 
        p.Id, 
        p.Title, 
        p.Score,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy ph ON p.ParentId = ph.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteStatistics AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.Score,
    upv.UpVotes,
    downv.DownVotes,
    COUNT(c.Id) AS CommentCount,
    SUM(badge.BadgeCount) AS TotalBadges,
    MAX(badge.GoldBadges) AS GoldBadges,
    MAX(badge.SilverBadges) AS SilverBadges,
    MAX(badge.BronzeBadges) AS BronzeBadges,
    ARRAY_AGG(DISTINCT t.TagName) AS TagsList,
    RANK() OVER (PARTITION BY ph.Level ORDER BY ph.Score DESC) AS ScoreRank
FROM 
    RecursivePostHierarchy ph
LEFT JOIN 
    Comments c ON c.PostId = ph.PostId
LEFT JOIN 
    PostVoteStatistics upv ON upv.PostId = ph.PostId
LEFT JOIN 
    PostVoteStatistics downv ON downv.PostId = ph.PostId
LEFT JOIN 
    UserBadges badge ON badge.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ph.PostId) 
LEFT JOIN 
    UNNEST(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')) AS t(TagName) ON Posts.Id = ph.PostId
GROUP BY 
    ph.PostId, ph.Title, ph.Score, upv.UpVotes, downv.DownVotes
ORDER BY 
    ph.Score DESC, ph.PostId ASC
LIMIT 100;

