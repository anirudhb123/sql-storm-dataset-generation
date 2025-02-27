
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags, u.DisplayName
),
TagStatistics AS (
    SELECT 
        REPLACE(tag.tagname, '<', '') AS CleanedTag,
        COUNT(*) AS PostCount,
        AVG(p.ViewCount) AS AvgViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tagname
         FROM Posts p
         JOIN (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
               UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
         ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1) AS tag
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        CleanedTag
),
TopTags AS (
    SELECT 
        CleanedTag,
        PostCount,
        AvgViews,
        AvgScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
    WHERE 
        PostCount > 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerName,
    rp.CommentCount,
    tt.CleanedTag,
    tt.AvgViews,
    tt.AvgScore
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON FIND_IN_SET(tt.CleanedTag, REPLACE(SUBSTRING(rp.Tags, 2, LENGTH(rp.Tags) - 2), '><', ',')) 
WHERE 
    rp.Rank <= 3 
ORDER BY 
    tt.PostCount DESC, rp.ViewCount DESC;
