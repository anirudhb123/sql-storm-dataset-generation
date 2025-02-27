WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        P.Title,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL

    UNION ALL

    SELECT 
        P.Id,
        P.ParentId,
        P.Title,
        RP.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy RP ON P.ParentId = RP.PostId
),
PostVoteStats AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
RankedPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        PS.UpVotes,
        PS.DownVotes,
        PS.TotalVotes,
        DENSE_RANK() OVER (ORDER BY PS.UpVotes DESC, PS.TotalVotes DESC) AS PostRank
    FROM 
        RecursivePostHierarchy RP
    LEFT JOIN 
        PostVoteStats PS ON RP.PostId = PS.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    COALESCE(PS.UpVotes, 0) AS UpVotes,
    COALESCE(PS.DownVotes, 0) AS DownVotes,
    RP.PostRank
FROM 
    RankedPosts RP
LEFT JOIN 
    PostVoteStats PS ON RP.PostId = PS.PostId
WHERE 
    RP.PostRank <= 10
ORDER BY 
    RP.PostRank;

This query performs the following:
1. **Recursive CTE** (`RecursivePostHierarchy`): It builds a hierarchy of posts, identifying top-level posts and their children based on parent-child relationships.
2. **Vote statistics CTE** (`PostVoteStats`): It calculates total upvotes, downvotes, and total votes for each post using conditional aggregation.
3. **Ranking Posts** (`RankedPosts`): It ranks the posts based on upvotes first and total votes second.
4. **Final Selection**: It selects the top 10 posts based on the ranking and displays their title along with upvote and downvote counts, ensuring that potential NULL values are replaced with zero for a cleaner output. 

This query effectively demonstrates the capabilities of SQL with joins, aggregation, recursive queries, window functions, and rank-based selection.
