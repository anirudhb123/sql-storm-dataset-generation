WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId -- Join to get answers
    LEFT JOIN 
        Comments c ON p.Id = c.PostId -- Join to get comments
    LEFT JOIN 
        Votes v ON p.Id = v.PostId -- Join to get votes
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id -- Join to get user details
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, p.Tags, u.DisplayName
), 
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Body,
        Tags,
        OwnerDisplayName,
        AnswerCount,
        CommentCount,
        VoteCount,
        PostRank
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5 -- Get the last 5 posts per user
)
SELECT 
    p.PostId,
    p.Title,
    p.OwnerDisplayName,
    p.CreationDate,
    p.AnswerCount,
    p.CommentCount,
    p.VoteCount,
    STRING_AGG(t.TagName, ', ') AS Tags 
FROM 
    FilteredPosts p
LEFT JOIN 
    Tags t ON t.TagName = ANY(STRING_TO_ARRAY(p.Tags, ', ')) -- Split tags into array and join with Tags table
GROUP BY 
    p.PostId, p.Title, p.OwnerDisplayName, p.CreationDate, p.AnswerCount, p.CommentCount, p.VoteCount
ORDER BY 
    p.CreationDate DESC;

