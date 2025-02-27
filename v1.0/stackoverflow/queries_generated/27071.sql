WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(t.TagName, ', ') AS TagsList,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        PostsTags pt ON p.Id = pt.PostId
    LEFT JOIN 
        Tags t ON pt.TagId = t.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, U.DisplayName
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.TagsList,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 3 -- Top 3 questions per user
),

PostDetails AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.TagsList,
        p.OwnerDisplayName,
        COALESCE(ph.Comment, 'No comments provided') AS LastEditComment,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        TopPosts p
    LEFT JOIN 
        PostHistory ph ON p.PostId = ph.PostId AND (ph.PostHistoryTypeId IN (4, 5, 6)) -- Edit title, body, tags
    GROUP BY 
        p.PostId, p.Title, p.CreationDate, p.ViewCount, p.Score, p.TagsList, p.OwnerDisplayName, ph.Comment
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.TagsList,
    pd.LastEditComment,
    pd.LastEditDate,
    DATEDIFF(CURRENT_TIMESTAMP, pd.CreationDate) AS DaysSincePosted
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 50;
