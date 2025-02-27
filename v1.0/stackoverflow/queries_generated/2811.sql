WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        u.DisplayName AS OwnerDisplayName, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
),
AggregatedVotes AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        COALESCE(v.Upvotes, 0) AS Upvotes,
        COALESCE(v.Downvotes, 0) AS Downvotes,
        (COALESCE(v.Upvotes, 0) - COALESCE(v.Downvotes, 0)) AS VoteBalance
    FROM 
        RankedPosts rp
    LEFT JOIN 
        AggregatedVotes v ON rp.PostId = v.PostId
    WHERE 
        rp.rn = 1
)
SELECT 
    pd.Title, 
    pd.CreationDate, 
    pd.OwnerDisplayName, 
    pd.Score, 
    pd.Upvotes, 
    pd.Downvotes,
    pd.VoteBalance,
    CASE 
        WHEN pd.VoteBalance > 0 THEN 'Positive'
        WHEN pd.VoteBalance < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteStatus
FROM 
    PostDetails pd
ORDER BY 
    pd.VoteBalance DESC, 
    pd.CreationDate DESC
LIMIT 10;

WITH CommentCounts AS (
    SELECT 
        PostId, 
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT DISTINCT 
        PostId
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    pd.Title,
    pd.CommentCount,
    CASE 
        WHEN cp.PostId IS NOT NULL THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus
FROM 
    PostDetails pd
LEFT JOIN 
    CommentCounts cc ON pd.PostId = cc.PostId
LEFT JOIN 
    ClosedPosts cp ON pd.PostId = cp.PostId;
