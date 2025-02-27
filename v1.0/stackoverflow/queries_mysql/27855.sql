
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 
                         WHEN v.VoteTypeId = 3 THEN -1 
                         ELSE 0 END), 0) AS Score
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2022-01-01' 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        FilteredPosts 
    INNER JOIN 
        (SELECT 
            1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
            UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.OwnerDisplayName,
        fp.CreationDate,
        fp.CommentCount,
        fp.Score,
        phs.EditCount,
        phs.LastEditDate,
        (SELECT GROUP_CONCAT(pt.TagName) FROM PopularTags pt) AS PopularTags
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        PostHistoryStats phs ON fp.PostId = phs.PostId
)
SELECT 
    *
FROM 
    FinalResults
ORDER BY 
    Score DESC, CommentCount DESC;
