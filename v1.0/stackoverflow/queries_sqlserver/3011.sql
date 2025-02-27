
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(NULLIF(u.DisplayName, ''), 'Anonymous') AS OwnerDisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        h.CreationDate AS CloseDate,
        h.UserDisplayName AS CloserDisplayName,
        h.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory h ON p.Id = h.PostId 
    WHERE 
        h.PostHistoryTypeId = 10
),
FinalOutput AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes,
        ub.BadgeNames,
        cp.CloseDate,
        cp.CloserDisplayName,
        cp.CloseReason
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.PostId = ub.UserId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.Rank = 1
    ORDER BY 
        rp.CreationDate DESC
)
SELECT 
    DISTINCT f.*,
    CASE 
        WHEN f.CloseDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    FinalOutput f
WHERE 
    f.Title LIKE '%sql%'
    AND (f.CloseDate IS NULL OR f.CloseDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56'))
ORDER BY 
    f.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
