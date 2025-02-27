WITH RecursiveUserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MIN(b.Date) AS FirstBadgeDate
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(CAST(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS INT), 0) AS UpVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PostDetails AS (
    SELECT 
        p.Id,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Title,
        p.CreationDate,
        ap.ViewCount,
        ap.Score,
        ap.UpVoteCount,
        rb.BadgeCount,
        rb.FirstBadgeDate
    FROM 
        Posts p
    JOIN 
        ActivePosts ap ON p.Id = ap.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        RecursiveUserBadges rb ON u.Id = rb.UserId
    WHERE 
        p.PostTypeId = 1  -- Considering questions only
),
CloseReasonCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasonCount,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        ph.PostId
),
FinalPostAnalysis AS (
    SELECT 
        pd.*,
        crc.CloseReasonCount,
        crc.FirstClosedDate
    FROM 
        PostDetails pd
    LEFT JOIN 
        CloseReasonCounts crc ON pd.Id = crc.PostId
)
SELECT 
    fpa.Title,
    fpa.OwnerDisplayName,
    fpa.ViewCount,
    fpa.Score,
    fpa.UpVoteCount,
    fpa.BadgeCount,
    fpa.FirstBadgeDate,
    COALESCE(fpa.CloseReasonCount, 0) AS CloseReasonCount,
    fpa.FirstClosedDate
FROM 
    FinalPostAnalysis fpa
ORDER BY 
    fpa.Score DESC, fpa.ViewCount DESC;
