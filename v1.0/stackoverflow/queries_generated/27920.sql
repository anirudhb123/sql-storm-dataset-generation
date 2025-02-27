WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COALESCE(ar.AnswerCount, 0) AS Answers,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>')::int[])
    LEFT JOIN (
        SELECT ParentId, COUNT(*) AS AnswerCount 
        FROM Posts 
        WHERE PostTypeId = 2 
        GROUP BY ParentId
    ) ar ON ar.ParentId = p.Id
    LEFT JOIN (
        SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes 
        GROUP BY PostId
    ) vs ON vs.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
TopQuestions AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Tags,
        Answers,
        UpVotes,
        DownVotes,
        RankByViews
    FROM 
        RankedPosts
    WHERE 
        RankByViews <= 10
)

SELECT 
    tq.PostId,
    tq.Title,
    tq.CreationDate,
    tq.ViewCount,
    tq.Tags,
    tq.Answers,
    tq.UpVotes,
    tq.DownVotes,
    (CASE 
        WHEN tq.Answers > 0 THEN 'Has Answers'
        ELSE 'No Answers'
    END) AS Answer_Status,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = tq.PostId) AS CommentCount
FROM 
    TopQuestions tq
ORDER BY 
    tq.ViewCount DESC;
