
WITH PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
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
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
VoteStatistics AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    COALESCE(ph.Level, -1) AS HierarchyLevel,
    u.Reputation,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    vs.UpVotes,
    vs.DownVotes,
    CASE 
        WHEN vs.UpVotes IS NULL OR vs.UpVotes <= 0 THEN 'No Votes'
        ELSE 'Positive Net Votes: ' + CAST((vs.UpVotes - COALESCE(vs.DownVotes, 0)) AS VARCHAR)
    END AS VoteSummary,
    STRING_AGG(t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags
FROM 
    Posts p
LEFT JOIN 
    PostHierarchy ph ON p.Id = ph.Id
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    VoteStatistics vs ON p.Id = vs.PostId
CROSS APPLY (
        SELECT 
            value AS TagName
        FROM 
            STRING_SPLIT(p.Tags, ',') 
    ) t
WHERE 
    p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
GROUP BY 
    p.Id, p.Title, ph.Level, u.Reputation, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges, vs.UpVotes, vs.DownVotes
ORDER BY 
    p.LastActivityDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
