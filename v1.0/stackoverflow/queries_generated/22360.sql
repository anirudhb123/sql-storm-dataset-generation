WITH UserReputation AS (
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
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) FILTER (WHERE v.BountyAmount IS NOT NULL) AS AvgBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart, BountyClose
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
),
FilteredPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.CommentCount,
        COALESCE(rp.PostHistoryTypeId = 10, FALSE) AS IsClosed -- Check if post is closed
    FROM 
        PostDetails pd
    LEFT JOIN 
        RecentPostHistory rp ON pd.PostId = rp.PostId AND rp.rn = 1
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.GoldBadges + ur.SilverBadges + ur.BronzeBadges AS TotalBadges,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.CommentCount,
    fp.IsClosed,
    CASE 
        WHEN fp.IsClosed THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus,
    (SELECT 
        STRING_AGG(tag.TagName, ', ') 
     FROM 
        Tags tag 
     JOIN 
        LATERAL string_to_array(fp.Title, ' ') AS words ON tag.TagName = words 
     WHERE 
        tag.Count > 0) AS RelevantTags
FROM 
    UserReputation ur
JOIN 
    FilteredPosts fp ON ur.UserId = fp.OwnerUserId
WHERE 
    ur.Reputation > 100 
ORDER BY 
    ur.Reputation DESC, fp.CreationDate ASC
LIMIT 50;
