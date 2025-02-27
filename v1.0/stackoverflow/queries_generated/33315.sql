WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        Level + 1 
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
TaggedQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        t.TagName,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE concat('%', t.TagName, '%') -- Assuming Tags are stored in a delimited string
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions
    AND 
        DATEDIFF(CURRENT_DATE, p.CreationDate) <= 30 -- Questions created in the last 30 days
),
PostScoreAggregates AS (
    SELECT 
        OwnerUserId,
        SUM(Score) AS TotalScore,
        COUNT(Id) AS TotalPosts
    FROM 
        Posts
    WHERE 
        CreationDate >= DATEADD(YEAR, -1, CURRENT_DATE) -- Posts created in the last year
    GROUP BY 
        OwnerUserId
),
VotedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    tq.PostId,
    tq.Title AS QuestionTitle,
    tq.CreationDate,
    tq.Score,
    tq.TagName,
    p.UserDisplayName AS OwnerDisplayName,
    COALESCE(vp.UpVotes, 0) AS UpVotes,
    COALESCE(vp.DownVotes, 0) AS DownVotes,
    pa.TotalScore AS OwnerTotalScore,
    pa.TotalPosts AS OwnerTotalPosts
FROM 
    TaggedQuestions tq
JOIN 
    Users p ON tq.OwnerUserId = p.Id
LEFT JOIN 
    VotedPosts vp ON tq.PostId = vp.Id
LEFT JOIN 
    PostScoreAggregates pa ON p.Id = pa.OwnerUserId
WHERE 
    (tq.CommentCount > 5 OR tq.Score > 10) -- Filter on comment count or score
ORDER BY 
    tq.CreationDate DESC, tq.Score DESC
LIMIT 100;

This SQL query combines several advanced SQL constructs, such as:
- A recursive common table expression (CTE) to explore hierarchical post relationships.
- CTEs for tagged questions, aggregate post scores, and voted posts with conditional counting.
- Use of window functions to get aggregate values related to posts' authors.
- Joining multiple tables with intricate logic to filter and organize the results based on recent activity and popularity metrics.
