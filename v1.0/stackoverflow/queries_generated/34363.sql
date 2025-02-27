WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- Bounties
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
    GROUP BY 
        p.Id, U.DisplayName
),
HighScorePosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount,
        TotalBounties
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5  -- Top 5 posts of each type
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName AS Editor,
        ph.Comment,
        p.Title
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10)  -- Edit Title, Edit Body, Post Closed
)
SELECT 
    h.PostId,
    h.Title,
    h.OwnerDisplayName,
    h.ViewCount,
    h.Score,
    h.CommentCount,
    h.TotalBounties,
    p.HistoryDate,
    p.Editor,
    p.Comment AS EditComment,
    COALESCE(h.Score * 0.1, 0) AS WeightedScore -- Weighted score calculation
FROM 
    HighScorePosts h
LEFT JOIN 
    PostHistoryDetails p ON h.PostId = p.PostId
ORDER BY 
    h.Score DESC, h.ViewCount DESC;
