WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Body, 
        P.CreationDate, 
        U.DisplayName AS OwnerDisplayName, 
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes, 
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '30 days' -- posts created in the last 30 days
    GROUP BY 
        P.Id, U.DisplayName
),
MostVotedPosts AS (
    SELECT 
        RP.*, 
        PT.Name AS PostTypeName,
        CASE 
            WHEN PT.Id = 1 THEN 'Question'
            WHEN PT.Id = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostNature
    FROM 
        RankedPosts RP
    JOIN 
        PostTypes PT ON RP.PostTypeId = PT.Id
    WHERE 
        Rank <= 10 -- Top 10 posts by score for each post type
)
SELECT 
    M.PostId,
    M.Title,
    M.Body,
    M.CreationDate,
    M.OwnerDisplayName,
    M.PostTypeName,
    M.Score,
    M.ViewCount,
    M.UpVotes,
    M.DownVotes,
    COALESCE(S.LikeCount, 0) AS LikeCount, -- Assuming a hypothetical Like count
    COALESCE(C.CommentCount, 0) AS CommentCount
FROM 
    MostVotedPosts M
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
) C ON M.PostId = C.PostId
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(*) AS LikeCount
    FROM 
        Votes
    WHERE 
        VoteTypeId = 2 -- Likes are counted as upvotes
    GROUP BY 
        PostId
) S ON M.PostId = S.PostId
ORDER BY 
    M.Score DESC, M.ViewCount DESC;
This SQL query benchmarks string processing by retrieving the top voted posts from the last 30 days categorized by post type (Questions and Answers). It constructs a CTE to rank posts, gathers their details, counts likes, and comments, and organizes results in descending order according to their score and view count.
