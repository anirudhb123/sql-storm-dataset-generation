WITH RecursivePostHierarchy AS (
    -- Recursive CTE to get the hierarchy of questions and answers
    SELECT 
        Id,
        Title,
        ParentId,
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Starting with Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON rph.Id = p.ParentId
    WHERE 
        p.PostTypeId = 2  -- Join to Answers
),

VoteStats AS (
    -- Summarize vote types per post
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) - COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS NetVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),

PostWithTags AS (
    -- Get post details with tags
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        t.TagName,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        COALESCE(vs.NetVotes, 0) AS NetVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostTags pt ON p.Id = pt.PostId
    LEFT JOIN 
        Tags t ON pt.TagId = t.Id
    LEFT JOIN 
        VoteStats vs ON p.Id = vs.PostId
),

FilteredPosts AS (
    -- Filter posts that have a significant number of votes and more than two answers
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COUNT(a.Id) AS AnswerCount,
        AVG(v.NetVotes) AS AverageVotes
    FROM 
        PostWithTags p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
    HAVING 
        COUNT(a.Id) > 2 AND AVG(v.NetVotes) > 5
),

FinalResult AS (
    SELECT 
        fh.Id AS PostId,
        fh.Title,
        fh.CreationDate,
        fh.AverageVotes,
        r.Level AS AnswerLevel,
        ROW_NUMBER() OVER (PARTITION BY fh.Id ORDER BY r.Level DESC) AS RowNum
    FROM 
        FilteredPosts fh
    LEFT JOIN 
        RecursivePostHierarchy r ON fh.Id = r.ParentId
)

SELECT 
    fr.PostId,
    fr.Title AS PostTitle,
    fr.CreationDate,
    fr.AverageVotes AS PostAverageVotes,
    fr.AnswerLevel,
    CASE 
        WHEN fr.AnswerLevel = 0 THEN 'Question'
        WHEN fr.AnswerLevel > 0 THEN 'Answer'
        ELSE 'Unknown'
    END AS PostType,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    FinalResult fr
LEFT JOIN 
    PostWithTags pwt ON fr.PostId = pwt.Id
LEFT JOIN 
    Tags t ON pwt.TagName = t.TagName
GROUP BY 
    fr.PostId, fr.Title, fr.CreationDate, fr.AverageVotes, fr.AnswerLevel
ORDER BY 
    fr.AverageVotes DESC, fr.CreationDate DESC;
