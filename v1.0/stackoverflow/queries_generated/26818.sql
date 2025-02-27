WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2) ORDER BY p.CreationDate DESC) AS RankByTag
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
TopRankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankByTag = 1
),
PostDetails AS (
    SELECT 
        trp.*,
        COUNT(pm.Id) AS AnswerCount,
        JSON_AGG(
            JSON_BUILD_OBJECT(
                'CommentId', c.Id,
                'Text', c.Text,
                'CreationDate', c.CreationDate,
                'UserDisplayName', c.UserDisplayName
            )
        ) AS Comments
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        Posts pm ON trp.PostId = pm.ParentId -- Join to gather answers
    LEFT JOIN 
        Comments c ON pm.Id = c.PostId -- Gather comments on answers
    GROUP BY 
        trp.PostId, trp.Title, trp.Body, trp.CreationDate, trp.Score, trp.ViewCount, trp.OwnerDisplayName
)
SELECT 
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.OwnerDisplayName,
    COALESCE(pd.Comments, '[]') AS Comments -- Default to empty JSON array if no comments
FROM 
    PostDetails pd
WHERE 
    pd.Score > 10 -- Filter for posts above a certain score threshold
ORDER BY 
    pd.ViewCount DESC; -- Order by view count for popularity
