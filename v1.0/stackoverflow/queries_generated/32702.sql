WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
), 
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 10
), 
UserVotes AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
), 
PostHistory AS (
    SELECT 
        PH.PostId,
        array_agg(PH.Comment) AS HistoryComments,
        COUNT(PH.Id) AS EditCount
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        PH.PostId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.ViewCount,
    TP.Score,
    TP.OwnerDisplayName,
    COALESCE(UV.UpVotes, 0) AS UpVotes,
    COALESCE(UV.DownVotes, 0) AS DownVotes,
    COALESCE(PH.HistoryComments, '{}') AS HistoryComments,
    COALESCE(PH.EditCount, 0) AS EditCount
FROM 
    TopPosts TP
LEFT JOIN 
    UserVotes UV ON TP.PostId = UV.PostId
LEFT JOIN 
    PostHistory PH ON TP.PostId = PH.PostId
WHERE 
    TP.Score >= 10
ORDER BY 
    TP.ViewCount DESC, TP.Score DESC;
This SQL query performs the following:

1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: Assigns ranks to posts based on their creation date for each post type, filtering for the last year.
   - `TopPosts`: Selects the top 10 recent posts for each post type.
   - `UserVotes`: Aggregates upvotes and downvotes on each post.
   - `PostHistory`: Gathers comments and counts edits for posts modified in the last year.

2. **Main Query**: Joins the results from CTEs, fetching relevant details from `TopPosts`, along with upvote/downvote counts, history comments, and edit counts.

3. **Filters**: Includes only posts with a score of 10 or more, and sorts them by view count and score in descending order.

This elaborate query provides a rich dataset for performance benchmarking scenarios, exploring how posts have engaged users, their editing history, and voting dynamics over time.
