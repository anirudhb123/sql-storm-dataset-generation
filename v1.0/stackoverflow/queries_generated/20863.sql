WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><') AS tag ON TRUE
    JOIN 
        Tags t ON tag = t.TagName
    GROUP BY 
        p.Id
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    WHERE 
        b.Date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        b.UserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(rb.BadgeCount, 0) AS RecentBadgeCount,
        COALESCE(rb.Badges, 'No Badges') AS RecentBadges,
        COALESCE(pp.PostCount, 0) AS TotalPostCount
    FROM 
        Users u
    LEFT JOIN 
        RecentBadges rb ON u.Id = rb.UserId
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(*) AS PostCount
        FROM 
            Posts
        WHERE 
            CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        GROUP BY 
            OwnerUserId
    ) pp ON u.Id = pp.OwnerUserId
)

SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    p.Title, 
    p.Tags,
    rp.Score,
    rp.UpVotes,
    rp.DownVotes,
    pp.TotalPostCount,
    CASE 
        WHEN pp.TotalPostCount = 0 THEN 'No Posts'
        WHEN pp.TotalPostCount < 10 THEN 'Novice'
        ELSE 'Veteran'
    END AS UserLevel,
    CASE 
        WHEN ARRAY_LENGTH(string_to_array(up.RecentBadges, ', '), 1) > 2 THEN 'Badge Collector'
        ELSE 'Minimalist'
    END AS BadgeSummary
FROM 
    UserActivity up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.PostId
LEFT JOIN 
    PostTags p ON rp.PostId = p.PostId
WHERE 
    up.Reputation > 1000 
    AND (rp.RankByScore <= 10 OR rp.PostId IS NULL)
ORDER BY 
    up.Reputation DESC, up.UserId ASC, rp.Score DESC
FETCH FIRST 50 ROWS ONLY;
