WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only considering questions
    GROUP BY 
        p.Id, u.DisplayName
),
StringProcessedData AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        CreationDate,
        LastActivityDate,
        CommentCount,
        VoteCount,
        ARRAY_LENGTH(string_to_array(Tags, '>'), 1) AS TagCount,
        CASE 
            WHEN LENGTH(Body) > 200 THEN substring(Body, 1, 200) || '...' -- Truncate body if it's longer than 200 characters
            ELSE Body 
        END AS ProcessedBody,
        PostRank
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5 -- Selecting the top 5 posts per user
),
FinalOutput AS (
    SELECT 
        s.*,
        EXTRACT(EPOCH FROM (NOW() - s.LastActivityDate)) AS DaysSinceLastActivity
    FROM 
        StringProcessedData s
    WHERE 
        s.DaysSinceLastActivity < 86400 -- Posts that are active within the last day
)
SELECT 
    PostId,
    Title,
    ProcessedBody,
    Tags,
    OwnerDisplayName,
    CreationDate,
    LastActivityDate,
    CommentCount,
    VoteCount,
    TagCount,
    DaysSinceLastActivity
FROM 
    FinalOutput
ORDER BY 
    VoteCount DESC, CreationDate DESC;
