-- This SQL query benchmarks string processing 
-- by analyzing posts, their associated tags, and user activity related to string handling.

WITH 
TagArray AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
),

TagActivity AS (
    SELECT 
        t.Tag,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(vote.Score, 0)) AS TotalVotes,
        ARRAY_AGG(DISTINCT u.DisplayName) AS UserContributors
    FROM 
        TagArray t
    JOIN 
        Posts p ON t.PostId = p.Id
    LEFT JOIN 
        Votes vote ON p.Id = vote.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.Tag
),

FrequentTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalVotes,
        UserContributors,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagActivity
    WHERE 
        PostCount > 10 -- Limit to tags with more than 10 questions
)

SELECT 
    f.Tag,
    f.PostCount,
    f.TotalVotes,
    f.UserContributors,
    ph.RevisionGUID,
    ph.CreationDate AS LastEditDate,
    u1.DisplayName AS LastEditor
FROM 
    FrequentTags f
JOIN 
    PostHistory ph ON f.Tag = ANY(SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) FROM Posts p WHERE p.Id = ph.PostId)
JOIN 
    Users u1 ON ph.UserId = u1.Id
WHERE 
    ph.PostHistoryTypeId IN (4, 5, 6) -- Including edits to title, body, and tags
ORDER BY 
    f.Rank;
