WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p 
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5 -- Top 5 posts per user
        AND rp.AnswerCount > 0 
        AND rp.UpVotes > rp.DownVotes -- More upvotes than downvotes
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.AnswerCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.Tags,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - fp.CreationDate))/3600 AS HoursSinceCreation
FROM 
    FilteredPosts fp
ORDER BY 
    fp.UpVotes DESC
LIMIT 10;
