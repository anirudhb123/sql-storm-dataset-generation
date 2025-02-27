WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        u.DisplayName AS OwnerName,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        LATERAL STRING_TO_ARRAY(p.Tags, ',') AS tag_ids ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_ids 
    WHERE 
        p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.Score, p.CreationDate
),

ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseComment,
        ph.UserDisplayName AS CloserName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),

MaxVotes AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    WHERE 
        VoteTypeId IN (2, 3) -- UpMod and DownMod
    GROUP BY 
        PostId
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    rp.PostId,
    rp.PostTitle,
    rp.OwnerName,
    rp.Score,
    rp.CreationDate,
    COALESCE(cp.CloseComment, 'Not Closed') AS CloseComment,
    COALESCE(cb.CloserName, 'N/A') AS CloserName,
    COALESCE(mv.TotalVotes, 0) AS TotalVotes,
    ub.BadgeCount,
    COALESCE(ub.Badges, 'No Badges') AS BadgeDetails,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top 5'
        ELSE 'Others'
    END AS PostCategory,
    CASE 
        WHEN cp.CloseRank IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS Status
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPostHistory cp ON rp.PostId = cp.PostId AND cp.CloseRank = 1
LEFT JOIN 
    MaxVotes mv ON rp.PostId = mv.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerName = (SELECT DisplayName FROM Users WHERE Id = ub.UserId)
WHERE 
    rp.CreationDate >= NOW() - INTERVAL '1 year' -- Only consider posts from the last year
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 100;
