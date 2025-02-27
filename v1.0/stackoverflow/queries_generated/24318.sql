WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6)
    WHERE 
        p.Type IN (1, 3) AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class = 1)::int AS GoldBadges,
        SUM(b.Class = 2)::int AS SilverBadges,
        SUM(b.Class = 3)::int AS BronzeBadges,
        AVG(EXTRACT(EPOCH FROM u.LastAccessDate - u.CreationDate) / 3600) AS AvgActiveHours
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount,
        us.DisplayName AS OwnerDisplayName,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        us.AvgActiveHours,
        CASE 
            WHEN rp.UpVotes > rp.DownVotes THEN 'Positive'
            WHEN rp.UpVotes < rp.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
)
SELECT 
    pm.*,
    CASE 
        WHEN pm.CommentCount > 10 THEN 'High Engagement'
        WHEN pm.CommentCount BETWEEN 5 AND 10 THEN 'Medium Engagement'
        ELSE 'Low Engagement'
    END AS EngagementCategory,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pm.PostId AND v.VoteTypeId = 4) AS BountyCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pm.PostId AND c.CreationDate > pm.CreationDate) AS NewCommentsCount
FROM 
    PostMetrics pm
WHERE 
    pm.GoldBadges > 1 OR pm.SilverBadges > 2 
ORDER BY 
    pm.UpVotes DESC NULLS LAST;
