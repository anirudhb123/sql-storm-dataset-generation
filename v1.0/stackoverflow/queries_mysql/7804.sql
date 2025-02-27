
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        @rank := IF(@prevOwnerUserId = p.OwnerUserId, @rank + 1, 1) AS Rank,
        @prevOwnerUserId := p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN 
        (SELECT @rank := 0, @prevOwnerUserId := NULL) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, p.PostTypeId, p.Tags
),
FilteredPosts AS (
    SELECT 
        rp.*,
        @overallRank := @overallRank + 1 AS OverallRank
    FROM 
        RankedPosts rp
    CROSS JOIN 
        (SELECT @overallRank := 0) AS vars
    WHERE 
        VoteCount > 5 AND 
        CommentCount > 2
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.CommentCount,
    fp.VoteCount,
    fp.OwnerDisplayName,
    fp.Tags,
    fp.PostType,
    fp.OverallRank
FROM 
    FilteredPosts fp
WHERE 
    OverallRank <= 50
ORDER BY 
    OverallRank;
