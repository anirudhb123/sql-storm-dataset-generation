WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.ParentId,
        1 AS Depth
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        P.Id, 
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.ParentId,
        R.Depth + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy R ON P.ParentId = R.PostId
),
PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(V.UpVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes,
        COALESCE(V.TotalVotes, 0) AS TotalVotes,
        (SELECT 
            COUNT(*) 
         FROM 
            Comments C 
         WHERE 
            C.PostId = P.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM P.CreationDate) ORDER BY P.CreationDate DESC) AS YearRank
    FROM 
        Posts P
    LEFT JOIN 
        PostVoteSummary V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        UpVotes, 
        DownVotes, 
        CommentCount
    FROM 
        PostActivity
    WHERE 
        YearRank <= 5
    ORDER BY 
        UpVotes DESC, 
        DownVotes ASC
)
SELECT 
    R.PostId,
    R.Title,
    R.Score,
    R.ViewCount,
    R.Depth,
    T.UpVotes,
    T.DownVotes,
    T.CommentCount
FROM 
    RecursivePostHierarchy R
LEFT JOIN 
    TopPosts T ON R.PostId = T.PostId
WHERE 
    R.Depth <= 3
ORDER BY 
    R.Depth, 
    T.UpVotes DESC NULLS LAST;

This SQL query does the following:

1. **Recursive CTE** (`RecursivePostHierarchy`): Constructs a hierarchy of posts based on their parent-child relationship. It starts with top-level posts (no parent) and recursively joins to get all child posts, along with a depth level.

2. **Vote Summary CTE** (`PostVoteSummary`): Aggregates vote information for each post, counting upvotes and downvotes.

3. **Post Activity CTE** (`PostActivity`): Combines posts with their vote counts and comment counts, also calculating a rank for each post based on its creation date within the past year.

4. **Top Posts CTE** (`TopPosts`): Selects only the top posts by upvotes and downvotes from the last year, further filtering for the top 5 in each year.

5. **Final Selection**: Joins the recursive post hierarchy with the top posts and filters for a maximum depth of 3. The final output is sorted by depth and upvotes, with `NULLS LAST` to place any posts without vote data at the end. 

The query employs complex logic involving CTEs, window functions, outer joins, and collates a lot of different post-related data, useful for performance benchmarking and testing query execution time across complex constructs.
