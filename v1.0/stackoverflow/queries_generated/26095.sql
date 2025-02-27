WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.OwnerDisplayName,
        ARRAY_AGG(DISTINCT SUBSTRING(t.TagName FROM 1 FOR 35)) AS Tags
    FROM 
        RankedPosts rp
    JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(SUBSTRING(rp.Tags FROM 2 FOR LENGTH(rp.Tags)-2), '><'))::int)
                            WHERE STRING_AGG(t.TagName, ',') IS NOT NULL)
    WHERE 
        rp.TagRank <= 3 -- Top 3 posts per tag
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.AnswerCount, rp.CommentCount, rp.OwnerDisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.AnswerCount,
    fp.CommentCount,
    fp.OwnerDisplayName,
    fp.Tags,
    COALESCE(ph.EditCount, 0) AS EditCount,
    ph.LastEdited
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistoryStats ph ON fp.PostId = ph.PostId
ORDER BY 
    fp.Score DESC, LastEdited DESC;
