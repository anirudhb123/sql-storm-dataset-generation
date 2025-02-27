
WITH UserScoreRankings AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
), 
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.OwnerUserId,
        RANK() OVER (ORDER BY P.ViewCount DESC) AS ViewCountRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '30 days'
), 
RecentComments AS (
    SELECT 
        C.PostId,
        C.Text,
        C.UserDisplayName,
        C.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY C.PostId ORDER BY C.CreationDate DESC) AS CommentRank
    FROM 
        Comments C
    WHERE 
        C.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '7 days'
)

SELECT 
    U.DisplayName AS CommenterName,
    U.Reputation AS CommenterReputation,
    PP.Title AS PostTitle,
    PP.ViewCount AS PostViewCount,
    PP.Score AS PostScore,
    RC.Text AS RecentCommentText,
    RC.CreationDate AS CommentCreationDate
FROM 
    PopularPosts PP
JOIN 
    RecentComments RC ON PP.PostId = RC.PostId
JOIN 
    UserScoreRankings U ON RC.UserDisplayName = U.DisplayName
WHERE 
    RC.CommentRank = 1
GROUP BY 
    U.DisplayName, U.Reputation, PP.Title, PP.ViewCount, PP.Score, RC.Text, RC.CreationDate
ORDER BY 
    PP.ViewCount DESC, U.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
