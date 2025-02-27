WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        string_agg(t.TagName, ', ') AS Tags,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
),
RecentVotes AS (
    SELECT 
        PostId,
        COUNT(*) AS VoteCount
    FROM 
        Votes
    WHERE 
        CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        PostId
),
CombinedData AS (
    SELECT 
        r.*, 
        COALESCE(rv.VoteCount, 0) AS RecentVoteCount
    FROM 
        RankedPosts r
    LEFT JOIN 
        RecentVotes rv ON r.PostId = rv.PostId
)
SELECT 
    PostId,
    Title,
    Body,
    Tags,
    Owner,
    CreationDate,
    Score,
    RecentVoteCount
FROM 
    CombinedData
WHERE 
    Rank <= 5 -- Top 5 questions for each user
ORDER BY 
    Owner, Score DESC;
