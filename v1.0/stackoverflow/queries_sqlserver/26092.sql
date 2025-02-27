
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TagStatistics AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount,
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore
    FROM 
        RankedPosts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    GROUP BY 
        value
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        AvgViewCount,
        AvgScore,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC, AvgViewCount DESC) AS TagRank
    FROM 
        TagStatistics
),
HighScorePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        t.TagName
    FROM 
        RankedPosts rp
    JOIN 
        TopTags t ON t.TagName IN (SELECT value FROM STRING_SPLIT(SUBSTRING(rp.Tags, 2, LEN(rp.Tags) - 2), '><'))
    WHERE 
        t.TagRank <= 5 AND rp.Rank = 1 
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.OwnerDisplayName,
    hsp.ViewCount,
    hsp.Score,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    HighScorePosts hsp
LEFT JOIN 
    Comments c ON hsp.PostId = c.PostId
LEFT JOIN 
    Votes v ON hsp.PostId = v.PostId
GROUP BY 
    hsp.PostId, hsp.Title, hsp.OwnerDisplayName, hsp.ViewCount, hsp.Score
ORDER BY 
    hsp.Score DESC, hsp.ViewCount DESC;
