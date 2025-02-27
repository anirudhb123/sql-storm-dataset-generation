WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS VoteCount,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS PostCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        LATERAL (
            SELECT unnest(string_to_array(p.Tags, '>')) AS TagName
        ) t ON TRUE
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS LatestPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId = 10) AS CloseHistoryCount
    FROM 
        Posts p
    WHERE 
        p.Id IN (SELECT PostId FROM PostHistory ph WHERE ph.PostHistoryTypeId = 10)
),
	UserReputation AS (
	SELECT 
        UserId,
        CASE 
            WHEN SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) > SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) THEN 'Positive'
            WHEN SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) > SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) THEN 'Negative'
            ELSE 'Neutral'
        END AS ReputationStatus
	FROM Votes
	GROUP BY UserId
)
SELECT 
    ua.DisplayName,
    ua.VoteCount,
    ua.PostCount,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    string_agg(DISTINCT u.Tags, ', ') AS UserTags,
    p.Title,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    c.CloseHistoryCount,
    ur.ReputationStatus
FROM 
    UserActivity ua
JOIN 
    PostMetrics p ON ua.UserId = p.OwnerUserId
LEFT JOIN 
    ClosedPosts c ON p.PostId = c.ClosedPostId
LEFT JOIN 
    UserReputation ur ON ua.UserId = ur.UserId
WHERE 
    p.LatestPostRank <= 5
GROUP BY 
    ua.UserId, p.PostId, c.CloseHistoryCount, ur.ReputationStatus
ORDER BY 
    ua.VoteCount DESC, p.UpVotes DESC
LIMIT 50;
