WITH RankedQuestions AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Body, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY v.CreationDate DESC) AS VoteRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
TopQuestions AS (
    SELECT 
        Id, 
        Title, 
        Body, 
        CreationDate, 
        OwnerDisplayName, 
        AnswerCount, 
        UpVotes
    FROM 
        RankedQuestions
    WHERE 
        VoteRank = 1
    ORDER BY 
        UpVotes DESC, 
        AnswerCount DESC
    LIMIT 10
)
SELECT 
    tq.Title, 
    tq.OwnerDisplayName, 
    tq.UpVotes, 
    tq.AnswerCount, 
    COALESCE(STRING_AGG(DISTINCT tg.TagName, ', '), 'No Tags') AS Tags
FROM 
    TopQuestions tq
LEFT JOIN 
    Posts p ON tq.Id = p.Id
LEFT JOIN 
    STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_ids 
    ON p.Id = tag_ids
LEFT JOIN 
    Tags tg ON tg.Id = tag_ids
GROUP BY 
    tq.Title, tq.OwnerDisplayName, tq.UpVotes, tq.AnswerCount
ORDER BY 
    tq.UpVotes DESC;
