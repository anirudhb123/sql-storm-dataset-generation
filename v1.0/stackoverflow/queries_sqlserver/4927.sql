
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes
    FROM 
        Users AS U
    LEFT JOIN 
        Posts AS P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes AS V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts AS P
    LEFT JOIN 
        Comments AS C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score
    HAVING COUNT(DISTINCT C.Id) > 5
),
PostDetails AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.Comment AS EditComment,
        PH.CreationDate AS EditDate,
        P.Title
    FROM 
        PostHistory AS PH
    JOIN 
        Posts AS P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6)
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    PP.Title AS PopularPostTitle,
    PP.CommentCount,
    PD.EditComment,
    PD.EditDate
FROM 
    UserActivity AS UA
JOIN 
    PopularPosts AS PP ON UA.PostCount > 10
LEFT JOIN 
    PostDetails AS PD ON PP.PostId = PD.PostId
WHERE 
    (UA.TotalVotes > 20 OR (UA.Reputation >= 1000 AND PP.CommentCount > 2))
ORDER BY 
    UA.Reputation DESC, PP.CommentCount DESC;
