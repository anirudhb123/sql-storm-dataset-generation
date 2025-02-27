WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, U.DisplayName
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
),
PostDetails AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.OwnerDisplayName,
        trp.Score,
        trp.ViewCount,
        trp.AnswerCount,
        trp.CommentCount,
        COALESCE(ph.Comment, 'No comments') AS LastEditComment,
        ph.CreationDate AS LastEditDate,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        PostHistory ph ON trp.PostId = ph.PostId AND ph.PostHistoryTypeId IN (4, 5)
    LEFT JOIN 
        PostsTags pt ON pt.PostId = trp.PostId
    LEFT JOIN 
        Tags t ON pt.TagId = t.Id
    GROUP BY 
        trp.PostId, trp.Title, trp.OwnerDisplayName, trp.Score, trp.ViewCount, trp.AnswerCount, trp.CommentCount, ph.Comment, ph.CreationDate
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.LastEditComment,
    pd.LastEditDate,
    pd.Tags
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
