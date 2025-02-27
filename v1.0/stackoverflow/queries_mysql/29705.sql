
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag, 
        Id AS PostId
    FROM 
        Posts 
    JOIN 
        (SELECT @row := @row + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) d, (SELECT @row := 0) r) n
    WHERE 
        PostTypeId = 1 AND n.n <= LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', '')) + 1
),
QuestionVotes AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,  
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes 
    FROM 
        Votes
    GROUP BY 
        PostId
),
QuestionDetails AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        p.Score,
        tc.Tag,
        qv.UpVotes,
        qv.DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        TagCounts tc ON p.Id = tc.PostId
    LEFT JOIN 
        QuestionVotes qv ON p.Id = qv.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, tc.Tag, qv.UpVotes, qv.DownVotes
),
Ranking AS (
    SELECT 
        QuestionId,
        Title,
        CreationDate,
        Score,
        Tag,
        UpVotes,
        DownVotes,
        CommentCount,
        @rank := IF(@prev_tag = Tag, @rank + 1, 1) AS RankWithinTag,
        @prev_tag := Tag
    FROM 
        QuestionDetails, (SELECT @rank := 0, @prev_tag := '') r 
    ORDER BY 
        Tag, (UpVotes - DownVotes) DESC, Score DESC
)
SELECT 
    r.QuestionId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.Tag,
    r.UpVotes,
    r.DownVotes,
    r.CommentCount,
    r.RankWithinTag
FROM 
    Ranking r
WHERE 
    r.RankWithinTag <= 5 
ORDER BY 
    r.Tag, r.RankWithinTag;
