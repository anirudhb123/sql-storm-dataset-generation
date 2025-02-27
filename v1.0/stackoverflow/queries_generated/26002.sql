WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 AND -- Only Questions
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY TagRank, CommentCount DESC) AS RowNum
    FROM 
        RankedPosts
    WHERE 
        TagRank = 1
),
TopPostDetails AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.Body,
        trp.OwnerDisplayName,
        trp.CommentCount,
        trp.AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        Posts p ON trp.PostId = p.Id
    LEFT JOIN 
        Tags t ON t.Id = ANY (STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')::int[])
    WHERE 
        trp.RowNum <= 10
    GROUP BY 
        trp.PostId, trp.Title, trp.Body, trp.OwnerDisplayName, trp.CommentCount, trp.AnswerCount
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.AnswerCount,
    pd.TagsList,
    ph.UserDisplayName AS LastEditor,
    ph.CreationDate AS LastEditDate,
    ph.Comment AS EditComment
FROM 
    TopPostDetails pd
LEFT JOIN 
    PostHistory ph ON pd.PostId = ph.PostId
WHERE 
    ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
ORDER BY 
    pd.CommentCount DESC, pd.AnswerCount DESC;
