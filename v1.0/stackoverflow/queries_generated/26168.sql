WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 -- Only questions
),
TagStatistics AS (
    SELECT
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1
    GROUP BY
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><'))
),
TaggedRankedPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.OwnerDisplayName,
        rp.CreationDate,
        ts.TagName,
        rp.RankByScore
    FROM
        RankedPosts rp
    JOIN
        TagStatistics ts ON rp.Tags LIKE '%' || ts.TagName || '%'
)
SELECT 
    tr.TagName,
    COUNT(tr.PostId) AS TotalPosts,
    AVG(tr.RankByScore) AS AvgRankByScore,
    COUNT(DISTINCT tr.OwnerDisplayName) AS UniqueAuthors
FROM 
    TaggedRankedPosts tr
GROUP BY 
    tr.TagName
HAVING 
    COUNT(tr.PostId) > 5 -- Filter to include only tags with more than 5 posts
ORDER BY 
    AvgRankByScore DESC, TotalPosts DESC;
