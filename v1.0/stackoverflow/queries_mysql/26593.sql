
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS AuthorName,
        u.Reputation AS AuthorReputation,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagsList
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT TagName FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '> <', numbers.n), '> <', -1) TagName
            FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
            WHERE numbers.n <= 1 + (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '> <', ''))) / LENGTH('> <')) ) AS temp) AS t ON TRUE
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, u.DisplayName, u.Reputation
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        CreationDate, 
        ViewCount, 
        AnswerCount, 
        AuthorName, 
        AuthorReputation,
        TagsList,
        @rank := @rank + 1 AS Rank
    FROM 
        PostDetails, (SELECT @rank := 0) r
    ORDER BY 
        ViewCount DESC
),
VoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN vt.Name = 'AcceptedByOriginator' THEN 1 END) AS AcceptedCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.ViewCount,
    tp.AnswerCount,
    tp.AuthorName,
    tp.AuthorReputation,
    tp.TagsList,
    vs.UpVotes,
    vs.DownVotes,
    vs.AcceptedCount
FROM 
    TopPosts tp
JOIN 
    VoteSummary vs ON tp.PostId = vs.PostId
WHERE 
    tp.Rank <= 10  
ORDER BY 
    tp.ViewCount DESC;
