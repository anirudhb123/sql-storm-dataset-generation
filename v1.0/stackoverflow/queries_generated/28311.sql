WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerName,
        ph.CreationDate AS LastEdited,
        ph.Comment AS EditComment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only for questions
        AND ph.PostHistoryTypeId IN (4, 5, 6)  -- Only title, body, and tags edits
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.LastEdited,
        STRING_AGG(rp.EditComment, '; ') AS EditComments,
        STRING_AGG(DISTINCT TRIM(BOTH '<>' FROM unnest(string_to_array(rp.Tags, '>'))) , ', ') AS FormattedTags
    FROM 
        RankedPosts rp
    WHERE 
        rp.EditRank = 1  -- Only get the most recent edit per post
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerName, rp.LastEdited
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerName,
        pd.LastEdited,
        pd.EditComments,
        pd.FormattedTags,
        p.Score,
        p.ViewCount
    FROM 
        PostDetails pd
    JOIN 
        Posts p ON pd.PostId = p.Id
    ORDER BY 
        p.Score DESC, pd.LastEdited DESC
    LIMIT 10  -- Get the top 10 posts by score
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerName,
    tp.LastEdited,
    tp.EditComments,
    tp.FormattedTags,
    tp.Score,
    tp.ViewCount,
    CASE 
        WHEN tp.Score > 50 THEN 'High Score'
        WHEN tp.Score BETWEEN 20 AND 50 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC;
