WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsList,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankPerUser,
        RANK() OVER (ORDER BY p.Score DESC) AS GlobalRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.TagsList,
        rp.RankPerUser,
        rp.GlobalRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.GlobalRank <= 10 AND
        rp.CommentCount > 5 -- Only interested in posts with more than 5 comments
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate AS HistoryDate,
        p.Title AS PostTitle,
        p.Body AS PostBody,
        ph.Comment AS EditComment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Title edits, body edits, tag edits
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.CommentCount,
    fp.TagsList,
    ARRAY_AGG(DISTINCT ph.HistoryDate || ': ' || ph.EditComment) AS EditHistory
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistoryInfo ph ON fp.PostId = ph.PostId
GROUP BY 
    fp.PostId, fp.Title, fp.OwnerDisplayName, fp.CreationDate, fp.Score, fp.ViewCount, fp.CommentCount, fp.TagsList
ORDER BY 
    fp.Score DESC, fp.CreationDate ASC;

