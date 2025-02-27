WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        pp.TagName AS MostUsedTag,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC, p.CreationDate DESC) AS RankedPost
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            unnest(string_to_array(Tags, '>')) AS TagName, 
            p.Id 
         FROM 
            Posts p) pp 
        ON 
            p.Id = pp.Id
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.PostCount,
    ua.CommentCount,
    ua.UpVotes,
    ua.DownVotes,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.MostUsedTag
FROM 
    UserActivity ua
LEFT JOIN 
    PostDetails pd ON ua.UserId = pd.OwnerUserId
WHERE 
    ua.Reputation > 1000
    AND (pd.RankedPost <= 5 OR pd.RankedPost IS NULL)
ORDER BY 
    ua.Reputation DESC, 
    pd.ViewCount DESC
LIMIT 50;

-- Additional complexity: 
-- Finding users who lost and regained badges in a month span with observations on their post activity.
WITH BadgesLost AS (
    SELECT 
        b.UserId,
        b.Name,
        b.Class,
        COUNT(DISTINCT b.Id) AS LostBadgeCount,
        MAX(b.Date) AS LastLostDate
    FROM 
        Badges b
    WHERE 
        b.Date <= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        b.UserId, b.Name, b.Class
),
BadgesRegained AS (
    SELECT 
        b.UserId,
        b.Name,
        b.Class,
        COUNT(DISTINCT b.Id) AS RegainedBadgeCount,
        MIN(b.Date) AS FirstRegainedDate
    FROM 
        Badges b
    WHERE 
        b.Date >= CURRENT_TIMESTAMP - INTERVAL '30 days'
        AND b.Class = 1 -- Focus on Gold badges
    GROUP BY 
        b.UserId, b.Name, b.Class
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(bl.LostBadgeCount, 0) AS LostBadges,
    COALESCE(br.RegainedBadgeCount, 0) AS RegainedBadges,
    CASE 
        WHEN COALESCE(bl.LostBadgeCount, 0) > 0 AND COALESCE(br.RegainedBadgeCount, 0) > 0 
        THEN 'Both Lost and Regained'
        WHEN COALESCE(bl.LostBadgeCount, 0) > 0 
        THEN 'Lost Badges'
        WHEN COALESCE(br.RegainedBadgeCount, 0) > 0 
        THEN 'Regained Badges'
        ELSE 'No Change'
    END AS BadgeStatus
FROM 
    Users u
LEFT JOIN 
    BadgesLost bl ON u.Id = bl.UserId
LEFT JOIN 
    BadgesRegained br ON u.Id = br.UserId
ORDER BY 
    u.Reputation DESC
LIMIT 50;
