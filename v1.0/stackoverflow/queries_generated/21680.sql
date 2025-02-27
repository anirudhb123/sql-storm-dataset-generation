WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        p.Tags,
        p.PostTypeId,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes, 
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        COALESCE(SUM(b.Id) OVER (PARTITION BY p.OwnerUserId), 0) AS TotalBadges,
        CASE 
            WHEN p.ViewCount IS NULL THEN 'Unknown Views'
            WHEN p.ViewCount = 0 THEN 'No Views Yet'
            ELSE CAST(p.ViewCount AS VARCHAR)
        END AS ViewCountStatus
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        p.CreationDate >= DATEADD(month, -12, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.OwnerUserId, p.Tags, p.PostTypeId
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, '; ') AS CloseReasons,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Close or Reopen
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        rp.*,
        cpd.CloseReasons,
        cpd.CloseCount,
        cpd.LastCloseDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPostDetails cpd ON rp.Id = cpd.PostId
    WHERE 
        rp.Rank <= 5 
        AND rp.PostTypeId = 1 -- Only questions
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.CloseReasons,
    tp.CloseCount,
    CASE 
        WHEN tp.CloseCount > 0 THEN 'Closed (' + CONVERT(VARCHAR, tp.CloseCount) + ' times)'
        ELSE 'Open'
    END AS PostStatus,
    tp.ViewCountStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC;

-- This query ranks posts by views, provides status and handles corner cases including displaying closed post reasons and handling NULL conditions.
