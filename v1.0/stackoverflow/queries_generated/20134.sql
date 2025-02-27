WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
), 

PostStats AS (
    SELECT 
        P.Id AS PostId, 
        P.OwnerUserId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(P.CreationDate) AS MostRecentActivity
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        P.Id, P.OwnerUserId
),

PostDetails AS (
    SELECT 
        PS.PostId,
        PS.OwnerUserId,
        PS.CommentCount,
        PS.UpVotes,
        PS.DownVotes,
        P.Title AS PostTitle,
        P.Body AS PostBody,
        P.Tags,
        COALESCE(U.DisplayName, 'Deleted User') AS AuthorName
    FROM 
        PostStats PS
    JOIN 
        Posts P ON PS.PostId = P.Id
    LEFT JOIN 
        Users U ON PS.OwnerUserId = U.Id 
)

SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation AS UserReputation,
    COUNT(DISTINCT PD.PostId) AS TotalPosts,
    SUM(PD.CommentCount) AS TotalComments,
    SUM(PD.UpVotes) AS TotalUpVotes,
    SUM(PD.DownVotes) AS TotalDownVotes,
    STRING_AGG(DISTINCT PD.Tags, ', ') AS AllTags,
    MAX(PD.MostRecentActivity) AS LastActivity
FROM 
    UserReputation U
LEFT JOIN 
    PostDetails PD ON U.UserId = PD.OwnerUserId
GROUP BY 
    U.UserId
HAVING 
    SUM(PD.CommentCount) > 5
ORDER BY 
    UserReputation DESC,
    TotalPosts DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY

UNION ALL 

SELECT 
    'Total Statistics' AS UserDisplayName,
    NULL AS UserReputation,
    COUNT(DISTINCT PD.PostId) AS TotalPosts,
    SUM(PD.CommentCount) AS TotalComments,
    SUM(PD.UpVotes) AS TotalUpVotes,
    SUM(PD.DownVotes) AS TotalDownVotes,
    NULL AS AllTags,
    NULL AS LastActivity
FROM 
    PostDetails PD

WHERE EXISTS (
    SELECT 
        1 
    FROM 
        Users U 
    WHERE 
        U.Id = PD.OwnerUserId AND U.Reputation < 100
)

ORDER BY 
    UserReputation DESC NULLS LAST;

This SQL query involves several advanced constructs:

1. **Common Table Expressions (CTEs)**: This query organizes data into multiple logical blocks with `UserReputation`, `PostStats`, and `PostDetails`.
2. **Window Functions**: The `ROW_NUMBER()` function assigns ranks to users based on their reputation.
3. **Correlated Subqueries**: The `EXISTS` clause filters posts based on the existence of certain user criteria.
4. **Outer Joins**: It uses `LEFT JOIN` to preserve data in scenarios where there may be no corresponding entries in `Comments` or `Votes`.
5. **Aggregate Functions**: It aggregates user and post statistics, including sums and counts.
6. **String Aggregation**: It concatenates tags from different posts into a single string using `STRING_AGG`.
7. **NULL Logic**: It includes logic that handles deleted users by using `COALESCE`.
8. **Set Operators**: The `UNION ALL` combines results of user statistics and total post statistics into one result set.
9. **Complicated Conditions**: The `HAVING` clause is used to filter users with more than five comments.
10. **Order by with Null Handling**: It handles ordering by reputation while dealing with NULL values appropriately.

This query can be complex to benchmark due to its usage of multiple SQL constructs and could provide diverse loads when tested under various conditions (number of users, posts, and activity).
