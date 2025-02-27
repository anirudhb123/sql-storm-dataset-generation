WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, '; ') AS HistoryComments,
        MIN(ph.CreationDate) AS FirstEditedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    COALESCE(phs.HistoryComments, 'No history') AS HistoryComments,
    phs.FirstEditedDate
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistorySummary phs ON tp.PostId = phs.PostId
ORDER BY 
    tp.UpVotes DESC;

-- Bonus Analysis
SELECT 
    COUNT(DISTINCT p.OwnerUserId) AS UniqueAuthors,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.Score) AS AverageScore,
    COUNT(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 END) AS ClosedPostCount
FROM 
    Posts p
WHERE 
    p.CreationDate BETWEEN NOW() - INTERVAL '5 years' AND NOW();

