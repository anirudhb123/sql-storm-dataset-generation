WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COALESCE(NULLIF(P.Body, ''), '<no content>') AS BodyContent,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= '2022-01-01'
),
ActiveUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.LastAccessDate > NOW() - INTERVAL '30 days'
),
PostTypesCount AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
TopCloseReasons AS (
    SELECT 
        PH.Comment,
        PH.PostId
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    ORDER BY 
        PH.CreationDate DESC
    LIMIT 5
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.BodyContent,
    AU.DisplayName AS ActiveUserName,
    PT.TotalPosts AS PostTypeTotal,
    TCR.Comment AS LastCloseReason
FROM 
    PostStats PS
LEFT JOIN 
    ActiveUsers AU ON PS.UserPostRank = 1
LEFT JOIN 
    PostTypesCount PT ON PS.PostId IN (SELECT P.Id FROM Posts P WHERE P.PostTypeId = PT.PostTypeId)
LEFT JOIN 
    TopCloseReasons TCR ON PS.PostId = TCR.PostId
WHERE 
    (PS.ViewCount > 1000 OR PS.Score > 10)
AND 
    (PS.AnswerCount > 0 OR PS.CommentCount > 5)
ORDER BY 
    PS.Score DESC,
    PS.ViewCount DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;

### Explanation
- **CTEs**: Several Common Table Expressions (CTEs) are used:
    - `PostStats` computes various statistics of posts created after 2022.
    - `ActiveUsers` identifies users who were active within the last 30 days and ranks them by reputation.
    - `PostTypesCount` counts the posts by type.
    - `TopCloseReasons` retrieves the most recent close reasons for posts.
  
- **LEFT JOINs**: Different pieces of information from the CTEs are combined, allowing for comprehensive data while preserving all entries from the `PostStats` CTE.

- **COALESCE and NULLIF**: Used to provide a default value if the body of a post is empty.

- **Sorting and Paging**: Results are ordered by score and view count, and pagination is implemented to fetch a specific data range.

- **Complex Filters**: The WHERE clause includes multiple conditions combined with logical operators to filter posts based on view count and engagement metrics.

- **Obscure SQL semantics**: The query reflects how one can deal with potentially NULL values in a way that respects SQL’s handling of non-standard semantics while ensuring the useful content is highlighted.
