
WITH TagCounts AS (
    SELECT 
        SPLIT(TRIM(BOTH '<>' FROM Tags), '><') AS TagArray, 
        Id AS PostId
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
),
TagArrayExpanded AS (
    SELECT 
        PostId, 
        Tag
    FROM 
        TagCounts, 
        LATERAL FLATTEN(input => TagArray) AS Tag
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
        te.Tag,
        qv.UpVotes,
        qv.DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        TagArrayExpanded te ON p.Id = te.PostId
    LEFT JOIN 
        QuestionVotes qv ON p.Id = qv.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, te.Tag, qv.UpVotes, qv.DownVotes
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
        RANK() OVER (PARTITION BY Tag ORDER BY (UpVotes - DownVotes) DESC, Score DESC) AS RankWithinTag
    FROM 
        QuestionDetails
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
