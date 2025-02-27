WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Body,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Tags t ON POSITION(CONCAT('<', t.TagName, '>') IN p.Tags) > 0
    WHERE
        p.PostTypeId = 1  -- Considering only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.Body, U.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Body,
        rp.Tags,
        rp.OwnerName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1  -- Only the latest question per user
),
CommentCounts AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.Body,
    fp.Tags,
    fp.OwnerName,
    COALESCE(cc.TotalComments, 0) AS TotalComments
FROM 
    FilteredPosts fp
LEFT JOIN 
    CommentCounts cc ON fp.PostId = cc.PostId
ORDER BY 
    fp.ViewCount DESC, fp.Score DESC
LIMIT 10;
