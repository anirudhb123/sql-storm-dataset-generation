
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= '2023-01-01 00:00:00' 
),
TagStatistics AS (
    SELECT 
        TRIM(tag) AS Tag,
        COUNT(*) AS PostCount,
        AVG(Score) AS AverageScore,
        SUM(ViewCount) AS TotalViews
    FROM (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '<>', n.n), '<>', -1) AS tag,
            Score,
            ViewCount
        FROM 
            Posts
        JOIN (
            SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '<>', '')) >= n.n - 1
        WHERE 
            PostTypeId = 1 
            AND CreationDate >= '2023-01-01 00:00:00'
    ) AS TagsTable
    GROUP BY 
        TRIM(tag)
),
TopVotes AS (
    SELECT 
        v.PostId,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= '2023-01-01 00:00:00'
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Body,
    rp.Tags,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    ts.PostCount,
    ts.AverageScore,
    ts.TotalViews,
    tv.VoteCount,
    rp.TagRank
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStatistics ts ON rp.Tags LIKE CONCAT('%', ts.Tag, '%')
LEFT JOIN 
    TopVotes tv ON rp.PostId = tv.PostId
WHERE 
    rp.TagRank <= 5 
ORDER BY 
    rp.TagRank, ts.AverageScore DESC, tv.VoteCount DESC;
