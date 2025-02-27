
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        AVG(VoteCount.votes) AS AvgVotes,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY COUNT(C.Id) DESC) AS RankByComments,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY AVG(VoteCount.votes) DESC) AS RankByVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS votes 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) AS VoteCount ON P.Id = VoteCount.PostId
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
    GROUP BY 
        P.Id, P.Title, P.PostTypeId
),
TopComments AS (
    SELECT 
        PostId, 
        Title 
    FROM 
        RankedPosts 
    WHERE 
        RankByComments <= 5
),
TopVotes AS (
    SELECT 
        PostId, 
        Title 
    FROM 
        RankedPosts 
    WHERE 
        RankByVotes <= 5
)
SELECT 
    COALESCE(TC.Title, TV.Title) AS Title, 
    TC.PostId AS CommentPostId, 
    TV.PostId AS VotePostId, 
    CASE WHEN TC.PostId IS NOT NULL THEN 1 ELSE 0 END AS HasTopComments, 
    CASE WHEN TV.PostId IS NOT NULL THEN 1 ELSE 0 END AS HasTopVotes
FROM 
    TopComments TC 
FULL OUTER JOIN 
    TopVotes TV ON TC.PostId = TV.PostId
ORDER BY 
    COALESCE(TC.Title, TV.Title);
