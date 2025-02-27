
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        @rownum := IF(@prevLocation = u.Location, @rownum + 1, 1) AS ScoreRank,
        @prevLocation := u.Location
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id,
        (SELECT @rownum := 0, @prevLocation := '') as r
    WHERE 
        p.PostTypeId = 1 
        AND u.Location IS NOT NULL
        AND u.Reputation > 1000
    ORDER BY 
        u.Location, p.Score DESC
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 10
),
PostTagCount AS (
    SELECT 
        fp.PostId,
        COUNT(*) AS TagCount
    FROM 
        FilteredPosts fp
    JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Tags, '><', numbers.n), '><', -1) AS tag
         FROM 
            (SELECT @rownum := @rownum + 1 as n
             FROM 
                (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers,
                (SELECT @rownum := 0) r) numbers) AS tag
    ON 
        tag.tag IS NOT NULL
    GROUP BY 
        fp.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.Score,
    fp.OwnerDisplayName,
    fp.CommentCount,
    pt.TagCount
FROM 
    FilteredPosts fp
JOIN 
    PostTagCount pt ON fp.PostId = pt.PostId
ORDER BY 
    pt.TagCount DESC, fp.Score DESC;
