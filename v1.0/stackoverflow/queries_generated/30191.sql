WITH RecursivePostHierarchy AS (
    -- Retrieve hierarchy of posts to find top-level questions and their respective answers
    SELECT 
        p.Id AS PostId, 
        p.Title,
        1 AS Level,
        p.AcceptedAnswerId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        a.Id AS PostId, 
        a.Title,
        r.Level + 1,
        a.AcceptedAnswerId
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy r ON a.ParentId = r.PostId
    WHERE 
        a.PostTypeId = 2 -- Answers only
),

PostVoteDetails AS (
    -- Retrieve count of votes for each post along with user reputation
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(u.Reputation) AS TotalUserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON v.UserId = u.Id
    GROUP BY 
        p.Id
),

PopularQuestions AS (
    -- Filter out popular questions based on score and view count
    SELECT 
        ph.PostId,
        ph.Title,
        pvd.VoteCount,
        pvd.UpVotes,
        pvd.DownVotes,
        pvd.TotalUserReputation,
        pa.Level
    FROM 
        RecursivePostHierarchy ph
    LEFT JOIN 
        PostVoteDetails pvd ON ph.PostId = pvd.PostId
    WHERE 
        pvd.VoteCount > 5 -- Popular threshold
        AND pvd.TotalUserReputation > 500 -- High reputation threshold
)

SELECT 
    pq.Title AS QuestionTitle,
    pq.VoteCount,
    pq.UpVotes,
    pq.DownVotes,
    pq.Level,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    PopularQuestions pq
LEFT JOIN 
    Posts p ON pq.PostId = p.Id
LEFT JOIN 
    LATERAL REGEXP_SPLIT_TO_TABLE(p.Tags, ',') AS tag ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = TRIM(tag)
GROUP BY 
    pq.PostId, pq.Title, pq.VoteCount, pq.UpVotes, pq.DownVotes, pq.Level
ORDER BY 
    pq.VoteCount DESC, pq.UpVotes DESC;
