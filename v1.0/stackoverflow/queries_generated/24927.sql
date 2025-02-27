WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COALESCE(ud.DisplayName, 'Deleted User') AS OwnerDisplayName,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users ud ON p.OwnerUserId = ud.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, ud.DisplayName, p.Score, p.CreationDate
),
PostAnalytics AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        Score,
        CreationDate,
        PostRank,
        CommentCount,
        UpVotes,
        DownVotes,
        (UpVotes - DownVotes) AS VoteBalance,
        CASE 
            WHEN VoteBalance > 10 THEN 'Highly popular'
            WHEN VoteBalance BETWEEN 1 AND 10 THEN 'Moderately popular'
            WHEN VoteBalance < 0 THEN 'Unpopular'
            ELSE 'Neutral'
        END AS PopularityStatus
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        cr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id 
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    pa.Title,
    pa.OwnerDisplayName,
    pa.Score,
    pa.CreationDate,
    pa.PopularityStatus,
    COALESCE(cp.CloseDate, 'Active') AS StatusDate,
    COALESCE(cp.CloseReason, 'Not Closed') AS ClosingReason,
    (EXTRACT(EPOCH FROM COALESCE(cp.CloseDate, NOW()) - pa.CreationDate) / 86400) AS DaysActive
FROM 
    PostAnalytics pa
LEFT JOIN 
    ClosedPosts cp ON pa.PostId = cp.PostId
WHERE 
    pa.VoteBalance >= 0
ORDER BY 
    pa.Score DESC, pa.CreationDate ASC;
