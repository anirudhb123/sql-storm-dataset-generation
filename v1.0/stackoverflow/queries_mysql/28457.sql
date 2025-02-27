
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        @row_number := IF(@prev_tag = p.Tags, @row_number + 1, 1) AS TagRank,
        @prev_tag := p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId,
        (SELECT @row_number := 0, @prev_tag := '') AS vars
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.Tags, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS FormattedTags,
        @overall_row_number := @overall_row_number + 1 AS OverallRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Tags t ON FIND_IN_SET(t.TagName, rp.Tags) > 0,
        (SELECT @overall_row_number := 0) AS overall_vars
    WHERE 
        rp.TagRank <= 5 
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.Tags, rp.OwnerDisplayName, rp.CommentCount
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.FormattedTags,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.OverallRank,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = fp.PostId AND v.VoteTypeId = 2) AS TotalUpvotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = fp.PostId AND v.VoteTypeId = 3) AS TotalDownvotes
FROM 
    FilteredPosts fp
ORDER BY 
    fp.OverallRank
LIMIT 100;
