
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PostBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN pht.Name = 'Initial Body' THEN ph.CreationDate END) AS BodyEditDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.Rank,
    rp.CommentCount,
    COALESCE(bc.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(bc.BadgeNames, 'No Badges') AS UserBadges,
    phd.ClosedDate,
    phd.BodyEditDate,
    CASE 
        WHEN rp.UpVotes > 0 THEN 'Popular'
        WHEN rp.DownVotes > 0 THEN 'Controversial'
        ELSE 'Neutral'
    END AS PopularityStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostBadgeCounts bc ON rp.OwnerUserId = bc.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.Rank = 1
ORDER BY 
    rp.Score DESC,
    rp.CreationDate ASC;
