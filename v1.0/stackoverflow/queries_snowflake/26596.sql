
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
            SPLIT(Tags, '<>') AS tag_array,
            Score,
            ViewCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 1 
            AND CreationDate >= '2023-01-01 00:00:00'
    ), 
    LATERAL FLATTEN(input => tag_array) AS tag
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
    TagStatistics ts ON POSITION(ts.Tag IN rp.Tags) > 0
LEFT JOIN 
    TopVotes tv ON rp.PostId = tv.PostId
WHERE 
    rp.TagRank <= 5 
ORDER BY 
    rp.TagRank, ts.AverageScore DESC, tv.VoteCount DESC;
