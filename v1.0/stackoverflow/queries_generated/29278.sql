WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) as Rank,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.Score,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.Score > 0 THEN 'Positive' 
        WHEN rp.Score < 0 THEN 'Negative' 
        ELSE 'Neutral' 
    END AS Score_Category,
    ARRAY_LENGTH(string_to_array(rp.Tags, '>'), 1) AS Tag_Count
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5 -- Top 5 posts per tag
ORDER BY 
    rp.Tags, rp.Score DESC;

-- This query benchmarks string processing with the depicted Post data, calculating scores and votes while categorizing them and determining tag counts. 
