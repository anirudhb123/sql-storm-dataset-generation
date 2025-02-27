WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId 
        AND a.PostTypeId = 2 -- Answers
    LEFT JOIN 
        (SELECT 
            PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM 
            Votes 
         GROUP BY 
            PostId) v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate
),
TopTags AS (
    SELECT 
        LOWER(TRIM(SUBSTRING(tag, 3, LENGTH(tag)-4))) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 AND Tags IS NOT NULL
        AND Tags <> '' 
    CROSS JOIN 
        UNNEST(string_to_array(Tags, '><')) AS tag
    GROUP BY 
        LOWER(TRIM(SUBSTRING(tag, 3, LENGTH(tag)-4)))
),
PopularPosts AS (
    SELECT 
        rp.PostId, rp.Title, SUM(tt.TagCount) AS PopularityScore
    FROM 
        RankedPosts rp
    JOIN 
        TopTags tt ON tt.TagName = ANY(SPLIT_PARTS(rp.Tags, '><')) -- Adjust split logic if needed
    GROUP BY 
        rp.PostId, rp.Title
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.PopularityScore,
    CAST(rp.CreationDate AS DATE) AS CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes
FROM 
    PopularPosts pp
JOIN 
    RankedPosts rp ON pp.PostId = rp.PostId
ORDER BY 
    pp.PopularityScore DESC, rp.ViewCount DESC;
