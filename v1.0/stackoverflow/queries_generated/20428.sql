WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        COALESCE(NULLIF(p.Body, ''), 'No Content') AS PostBody,
        ARRAY_LENGTH(string_to_array(p.Tags, '<>'), 1) AS TagCount,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10 -- Close reason only
    WHERE 
        p.Score > 0 
        AND (p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' OR p.ViewCount > 100)
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        rp.PostBody,
        rp.TagCount,
        rp.CloseReason
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 AND (rp.CloseReason IS NOT NULL OR rp.TagCount >= 3)
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.Score,
        fp.ViewCount,
        ua.UserId,
        ua.DisplayName,
        ua.BadgeCount,
        ua.TotalBounty,
        ua.LastVoteDate
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        UserActivity ua ON ua.UserId = (SELECT OwnerUserId FROM Posts p WHERE p.Id = fp.PostId)
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.DisplayName AS OwnerDisplayName,
    COALESCE(ps.BadgeCount, 0) AS BadgeCount,
    COALESCE(ps.TotalBounty, 0) AS TotalBounty,
    CASE 
        WHEN ps.LastVoteDate IS NULL THEN 'No voting activity' 
        ELSE TO_CHAR(ps.LastVoteDate, 'YYYY-MM-DD HH24:MI:SS') 
    END AS LastVoteFormatted,
    CASE 
        WHEN ps.CloseReason IS NULL THEN 'Open' 
        ELSE 'Closed: ' || ps.CloseReason 
    END AS PostStatus
FROM 
    PostSummary ps
WHERE 
    ps.Score > 5 
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC
LIMIT 50 OFFSET 0;
