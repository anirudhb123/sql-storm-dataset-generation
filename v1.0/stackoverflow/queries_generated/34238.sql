WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Reputation ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only Questions
        AND p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Posts from the last year
), 
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= DATEADD(MONTH, -2, GETDATE())  -- Votes from the last two months
    GROUP BY 
        v.PostId
), 
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(crt.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
    COALESCE(cv.CloseReasonNames, 'No close reasons') AS CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
LEFT JOIN 
    CloseReasons cv ON rp.PostId = cv.PostId
WHERE 
    rp.rn <= 5  -- Select top 5 posts for each reputation level
ORDER BY 
    rp.CreationDate DESC, 
    rp.Score DESC;
