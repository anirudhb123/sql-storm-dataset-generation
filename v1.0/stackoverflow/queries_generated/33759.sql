WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS Author,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, U.DisplayName
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        MIN(PH.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        PH.PostId
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        RP.Author,
        RP.CommentCount,
        COALESCE(CPH.CloseCount, 0) AS CloseCount,
        COALESCE(CPH.FirstClosedDate, 'No Closure') AS FirstClosedDate
    FROM 
        RankedPosts RP
    LEFT JOIN 
        ClosedPostHistory CPH ON RP.PostId = CPH.PostId
    WHERE 
        RP.ScoreRank <= 10 -- Top 10 posts by score for each PostType
)
SELECT 
    TP.*,
    CASE 
        WHEN TP.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    (SELECT STRING_AGG(TAG.TagName, ', ') 
     FROM Tags TAG 
     JOIN UNNEST(string_to_array(P.Tags, '><')) AS Tag ON TAG.TagName = Tag
     WHERE Tag IS NOT NULL) AS Tags
FROM 
    TopPosts TP
ORDER BY 
    TP.Score DESC, 
    TP.ViewCount DESC;

### Explanation:
1. **RankedPosts CTE**: This common table expression calculates the rank of posts based on their scores for each post type, also collecting the number of comments made on each post in the last year.

2. **ClosedPostHistory CTE**: This collects the count and date of closure for posts that have been closed.

3. **TopPosts CTE**: Combines the results of `RankedPosts` and `ClosedPostHistory`, pulling the top 10 posts by score for each post type while also gathering the relevant closure information.

4. **Final Selection**: This final SELECT statement determines the status of each post and gathers the tags associated with them, providing a consolidated view of the top posts configured to output in a descending order based on scores and views. 

5. **Window Functions**: The use of `RANK()` helps to establish post score ranking distinctly for different post types.

6. **String Aggression**: The final retrieval of tags employs a correlated subquery that makes use of `STRING_AGG` to concatenate the tags of each post. 

7. **Outer Joins**: Used to ensure that we retain posts even if they do not have certain associations (e.g., comments or closure history).

This intricate SQL query can serve as an effective benchmark for performance testing the database under various operational conditions.
