WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS UpVotes,  -- UpMod votes
        COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS DownVotes,  -- DownMod votes
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Only consider posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
PostHistoryWithReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT CONCAT('(', ct.Name, '): ', ph.Comment) ORDER BY ph.CreationDate DESC) AS CloseReasons,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ct ON ph.Comment::int = ct.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Considering closed and reopened posts only
    GROUP BY 
        ph.PostId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN ph.PostHistoryTypeId = 52 THEN 1 ELSE 0 END) AS HotQuestionsCount  -- Number of hot questions they've created
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        u.Reputation > 1000  -- Only consider users with high reputation
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    rp.UpVotes,
    rp.DownVotes,
    phwr.CloseReasons,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Latest Post'
        WHEN rp.PostRank IS NOT NULL THEN 'Older Post'
        ELSE 'Unranked'
    END AS PostStatus,
    au.DisplayName AS ActiveUser,
    au.HotQuestionsCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryWithReasons phwr ON rp.PostId = phwr.PostId
LEFT JOIN 
    ActiveUsers au ON rp.PostId IN (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.OwnerUserId = au.UserId
    )
WHERE 
    (rp.UpVotes - rp.DownVotes) > 0  -- Only include posts with net positive votes
AND 
    phwr.EditCount > 3  -- Posts with more than 3 edits
ORDER BY 
    rp.CreationDate DESC, 
    rp.Score DESC
LIMIT 10;
