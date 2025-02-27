WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByTags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- only questions
        AND p.Score > 0
),
HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.OwnerReputation
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByTags <= 5 -- top 5 posts per tag
),
VotesAggregated AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.Body,
    hsp.CreationDate,
    hsp.Score,
    hsp.ViewCount,
    hsp.Tags,
    hsp.OwnerDisplayName,
    hsp.OwnerReputation,
    va.VoteCount
FROM 
    HighScoringPosts hsp
JOIN 
    VotesAggregated va ON hsp.PostId = va.PostId
ORDER BY 
    hsp.Title ASC, hsp.Score DESC;

This query performs a detailed string processing benchmark by identifying high-scoring questions on Stack Overflow, aggregating user votes, and formatting the output for insightful analysis. It ranks posts based on their tags, filters them by score, and joins with the votes table to get the count of votes for each post, providing a comprehensive view of the most significant questions.
