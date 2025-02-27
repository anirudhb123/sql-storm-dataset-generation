WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPostsByOwner
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
ActiveBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 OR b.Class = 2 -- Only Gold and Silver badges
    GROUP BY 
        b.UserId
),
LatestVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        v.VoteTypeId,
        ROW_NUMBER() OVER (PARTITION BY v.PostId ORDER BY v.CreationDate DESC) AS VoteRank
    FROM 
        Votes v
    WHERE 
        v.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days' -- Votes in the last 30 days
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate > CURRENT_TIMESTAMP - INTERVAL '15 days' -- Comments in the last 15 days
    GROUP BY 
        c.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerName,
    rp.TotalPostsByOwner,
    COALESCE(ab.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(rc.CommentCount, 0) AS RecentCommentCount,
    CASE 
        WHEN lp.VoteTypeId IS NULL THEN 'No Recent Votes'
        WHEN lp.VoteTypeId = 2 THEN 'Upvoted'
        ELSE 'Downvoted'
    END AS RecentVoteStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    ActiveBadges ab ON rp.OwnerUserId = ab.UserId
LEFT JOIN 
    RecentComments rc ON rp.PostId = rc.PostId
LEFT JOIN 
    LatestVotes lp ON rp.PostId = lp.PostId AND lp.VoteRank = 1
WHERE 
    rp.OwnerPostRank <= 10 -- Top 10 posts by each user
ORDER BY 
    rp.CreationDate DESC, 
    TotalPostsByOwner DESC
LIMIT 100;

-- To explore corner cases, checking for NULL logic and string functions
SELECT 
    p.Id,
    p.Title,
    p.Body,
    CASE 
        WHEN bp.Name IS NULL THEN 'No History'
        ELSE bp.Name
    END AS LastPostHistoryType,
    REPLACE(REPLACE(p.Tags, '<tag>', ''), '</tag>', '') AS CleanedTags
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    PostHistoryTypes bp ON ph.PostHistoryTypeId = bp.Id
WHERE 
    p.CreationDate IS NOT NULL
    AND (p.ViewCount IS NULL OR p.ViewCount > 1000) -- Filter by view count
ORDER BY 
    p.CreationDate DESC
LIMIT 50;
