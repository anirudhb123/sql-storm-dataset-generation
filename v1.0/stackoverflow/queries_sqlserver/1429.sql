
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST(DATEADD(day, -30, '2024-10-01') AS date)
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        OwnerPostRank <= 5
),
VotesSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    ISNULL(ts.Upvotes, 0) AS Upvotes,
    ISNULL(ts.Downvotes, 0) AS Downvotes,
    ISNULL(ts.TotalVotes, 0) AS TotalVotes,
    CASE 
        WHEN ISNULL(ts.TotalVotes, 0) = 0 THEN 'No Votes'
        WHEN ISNULL(ts.Upvotes, 0) > ISNULL(ts.Downvotes, 0) THEN 'Positive'
        WHEN ISNULL(ts.Upvotes, 0) < ISNULL(ts.Downvotes, 0) THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    TopPosts tp
LEFT JOIN 
    VotesSummary ts ON tp.PostId = ts.PostId
ORDER BY 
    tp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
