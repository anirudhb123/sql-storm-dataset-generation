
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
        TRIM(REGEXP_SUBSTR(Tags, '[^><]+', 1, seq)) AS TagName,
        COUNT(*) AS TagCount,
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore
    FROM 
        RankedPosts,
        TABLE(GENERATOR(ROWCOUNT => 1000)) AS seq  -- Assume enough rows to cover all tags
    WHERE 
        REGEXP_SUBSTR(Tags, '[^><]+', 1, seq) IS NOT NULL
    GROUP BY 
        TagName
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
        TopTags t ON t.TagName IN (TRIM(REGEXP_SUBSTR(rp.Tags, '[^><]+', 1, seq)))
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
