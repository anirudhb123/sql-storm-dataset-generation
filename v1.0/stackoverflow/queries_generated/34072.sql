WITH RecursivePosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        1 AS Level,
        CAST(P.Title AS VARCHAR(MAX)) AS Path
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        P2.Id,
        P2.Title,
        P2.CreationDate,
        P2.Score,
        P2.ViewCount,
        P2.AnswerCount,
        RP.Level + 1,
        CAST(RP.Path + ' -> ' + P2.Title AS VARCHAR(MAX))
    FROM 
        Posts P2
        JOIN Posts P ON P2.ParentId = P.Id
        JOIN RecursivePosts RP ON P.Id = RP.Id
)
, PostVotes AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 WHEN V.VoteTypeId = 3 THEN -1 ELSE 0 END) AS NetVotes,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    RP.Id AS PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.AnswerCount,
    COALESCE(PV.NetVotes, 0) AS NetVotes,
    COALESCE(PV.UpVotes, 0) AS UpVotes,
    COALESCE(PV.DownVotes, 0) AS DownVotes,
    RP.Level,
    RP.Path
FROM 
    RecursivePosts RP
LEFT JOIN 
    PostVotes PV ON RP.Id = PV.PostId
WHERE 
    RP.Score > 0
ORDER BY 
    RP.Level DESC,
    NetVotes DESC,
    RP.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;

### Explanation
- **Recursive CTE (RecursivePosts)**: This Common Table Expression (CTE) recursively retrieves posts of type "questions" and their parent-child relationships (answers). It builds a hierarchy (path) to show relationships and levels.
- **Aggregated Votes (PostVotes)**: This second CTE calculates the net votes, including the count of upvotes and downvotes per post, sum them up based on the `VoteTypeId`.
- **Final Selection**: The main query selects required fields from both CTEs, using a LEFT JOIN to include posts even if they have no votes. 
- **Filters**: Only questions with a positive score are considered.
- **Ordering and Limiting Results**: The results are ordered by post level (hierarchy), net votes, and creation date, limiting results to the top 100 entries, making the query optimized for performance measuring in terms of handling recursion and aggregation.
