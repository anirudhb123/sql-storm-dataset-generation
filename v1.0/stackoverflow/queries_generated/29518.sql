WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank = 1
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Tags,
        tp.OwnerDisplayName,
        tp.CommentCount,
        COALESCE(pht.Comment, 'No comments yet') AS LastEditComment,
        pht.CreationDate AS LastEditDate,
        vh.CreationDate AS VoteDate,
        vt.Name AS VoteType
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostHistory pht ON tp.PostId = pht.PostId AND pht.PostHistoryTypeId IN (4, 5) -- Edit Title or Edit Body
    LEFT JOIN 
        Votes vh ON tp.PostId = vh.PostId
    LEFT JOIN 
        VoteTypes vt ON vh.VoteTypeId = vt.Id
)
SELECT 
    pd.Title,
    pd.Tags,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.LastEditComment,
    pd.LastEditDate,
    COUNT(DISTINCT vh.UserId) AS UniqueVoters,
    STRING_AGG(DISTINCT vt.Name, ', ') AS VoteTypes
FROM 
    PostDetails pd
LEFT JOIN 
    Votes vh ON pd.PostId = vh.PostId
GROUP BY 
    pd.PostId, pd.Title, pd.Tags, pd.OwnerDisplayName, pd.CommentCount, pd.LastEditComment, pd.LastEditDate
ORDER BY 
    pd.CommentCount DESC, pd.LastEditDate DESC
LIMIT 10;
