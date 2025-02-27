
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.ViewCount,
        p.Score,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    CROSS APPLY 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>') AS tag
    JOIN 
        Tags t ON t.TagName = tag.value
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        TagName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
),
PostDetails AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.CreationDate,
        trp.ViewCount,
        trp.Score,
        trp.TagName,
        STRING_AGG(c.Text, ' | ') AS Comments,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        Comments c ON c.PostId = trp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = trp.PostId
    GROUP BY 
        trp.PostId, trp.Title, trp.CreationDate, trp.ViewCount, trp.Score, trp.TagName
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.TagName,
    pd.Comments,
    pd.Upvotes,
    CASE 
        WHEN pd.Score > 10 THEN 'Popular'
        WHEN pd.Score BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Less Popular'
    END AS Popularity
FROM 
    PostDetails pd
ORDER BY 
    pd.ViewCount DESC,
    pd.Score DESC;
