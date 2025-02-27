WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '> <')) AS tagName ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tagName
    WHERE 
        p.PostTypeId = 1  -- We are mainly interested in Questions
    GROUP BY 
        p.Id, U.DisplayName, U.Reputation
),
PostWithMaxViews AS (
    SELECT 
        PostId,
        MAX(ViewCount) AS MaxViews
    FROM 
        RankedPosts
    GROUP BY 
        PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    COALESCE(pm.MaxViews, 0) AS MaxViews,
    CASE 
        WHEN rp.Score > 10 THEN 'Highly Active'
        WHEN rp.Score BETWEEN 1 AND 10 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM 
    RankedPosts rp
LEFT JOIN 
    PostWithMaxViews pm ON rp.PostId = pm.PostId
WHERE 
    rp.Rank <= 5  -- Retrieve top 5 latest questions per type
ORDER BY 
    rp.CreationDate DESC;
