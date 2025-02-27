WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(V.UpVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank,
        (SELECT COUNT(C.Id) 
         FROM Comments C 
         WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(B.Id) 
         FROM Badges B 
         WHERE B.UserId = P.OwnerUserId) AS BadgeCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    AND 
        P.Score > (SELECT AVG(Score) FROM Posts WHERE CreationDate >= NOW() - INTERVAL '1 year')
),
FilteredPosts AS (
    SELECT 
        RP.*,
        CASE 
            WHEN RP.Rank < 5 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostCategory,
        AVG(PH.CreationDate)::timestamp AS AvgHistoryDate
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostHistory PH ON RP.PostId = PH.PostId
    WHERE 
        RP.BadgeCount > 0
    GROUP BY 
        RP.PostId, RP.Title, RP.CreationDate, RP.Score, RP.UpVotes, RP.DownVotes, RP.Rank
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.CreationDate,
    FP.Score,
    FP.UpVotes,
    FP.DownVotes,
    FP.PostCategory,
    COALESCE(PH.Comment, 'No Comments') AS LastComment,
    FP.AvgHistoryDate
FROM 
    FilteredPosts FP
LEFT OUTER JOIN (
    SELECT 
        P.Id AS PostId,
        MAX(C.CreationDate) AS LastCommentDate,
        MAX(C.Text) AS Comment
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id
) PH ON FP.PostId = PH.PostId
ORDER BY 
    FP.Score DESC, FP.CreationDate ASC
FETCH FIRST 10 ROWS ONLY;

This SQL query is designed to provide a comprehensive performance benchmark by utilizing various SQL constructs. 

1. **Common Table Expressions (CTEs)**: Two CTEs are used. The first (`RankedPosts`) ranks posts based on their scores and calculates comment and badge counts. The second (`FilteredPosts`) categorizes the posts as "Top Post" or "Regular Post" based on their rank.

2. **Correlated Subqueries**: The count of comments and badges is calculated using correlated subqueries within the first CTE.

3. **Window Functions**: The `ROW_NUMBER()` function is utilized in the first CTE to rank posts within their post type.

4. **Outer Joins**: A left join is performed in both CTEs to include all posts even if there are no corresponding votes or comments.

5. **Conditionals**: The query includes complex predicates to filter results, ensuring it only returns posts from the last year, above average score, and with at least one badge.

6. **NULL Logic**: The query uses `COALESCE` to handle NULL values for upvotes and downvotes, ensuring that these fields always return a number.

7. **String Expressions**: The final output names "Top Post" and "Regular Post" are determined through a case expression, including fallback text for comments.

8. **Ordering and Fetching**: The results are ordered by score (descending) and creation date, limiting the result set to the top 10 posts.

This query explores various corner cases in SQL semantics while maintaining detailed insights into user engagement on posts.
