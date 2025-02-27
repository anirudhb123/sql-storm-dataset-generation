WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        LEAD(p.Score) OVER (ORDER BY p.CreationDate) AS NextPostScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE((SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id), 0) AS BadgeCount
    FROM 
        Users u
    WHERE 
        u.Reputation > (SELECT AVG(Reputation) FROM Users) -- Users above average reputation
),
PostHistoryAggregation AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        STRING_AGG(DISTINCT ph.UserDisplayName, ', ') AS Editors
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
HighActivityPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
    HAVING 
        COUNT(c.Id) > 10 -- Only include posts with more than 10 comments
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    u.DisplayName AS Owner,
    u.Reputation,
    u.BadgeCount,
    pha.ChangeCount,
    pha.Editors,
    hap.CommentCount,
    hap.UpVoteCount,
    hap.DownVoteCount,
    CASE 
        WHEN rp.NextPostScore IS NULL THEN 'N/A' 
        ELSE (rp.Score - rp.NextPostScore) 
    END AS ScoreDifference,
    CASE 
        WHEN rp.PostRank <= 3 THEN 'Top Post' 
        ELSE 'Regular Post' 
    END AS PostCategory
FROM 
    RankedPosts rp
JOIN 
    UserReputation u ON rp.OwnerUserId = u.UserId
LEFT JOIN 
    PostHistoryAggregation pha ON rp.PostId = pha.PostId
LEFT JOIN 
    HighActivityPosts hap ON rp.PostId = hap.PostId
WHERE 
    rp.PostRank <= 10 -- Limit to top 10 ranked posts
ORDER BY 
    rp.Score DESC
