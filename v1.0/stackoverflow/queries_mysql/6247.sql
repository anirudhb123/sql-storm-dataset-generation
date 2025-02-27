
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        @row_num := IF(@current_partition = p.PostTypeId, @row_num + 1, 1) AS Rank,
        @current_partition := p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2,
        (SELECT @row_num := 0, @current_partition := NULL) AS init
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, u.DisplayName
),
MostCommentedPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        CreationDate, 
        ViewCount, 
        OwnerDisplayName, 
        CommentCount, 
        Rank
    FROM 
        RankedPosts
    WHERE 
        CommentCount > 0
)
SELECT 
    mcp.PostId,
    mcp.Title,
    mcp.Score,
    mcp.CreationDate,
    mcp.ViewCount,
    mcp.OwnerDisplayName,
    mcp.CommentCount,
    COUNT(DISTINCT pht.UserId) AS EditCount,
    GROUP_CONCAT(DISTINCT pht.Comment SEPARATOR '; ') AS EditComments
FROM 
    MostCommentedPosts mcp
LEFT JOIN 
    PostHistory pht ON mcp.PostId = pht.PostId AND pht.PostHistoryTypeId IN (4, 5, 6, 24) 
GROUP BY 
    mcp.PostId, mcp.Title, mcp.Score, mcp.CreationDate, mcp.ViewCount, mcp.OwnerDisplayName, mcp.CommentCount, mcp.Rank
ORDER BY 
    mcp.Rank;
