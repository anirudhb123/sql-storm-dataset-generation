WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
), 
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id
), 
UserPostCounts AS (
    SELECT 
        PostDetails.OwnerUserId,
        COUNT(PostDetails.PostId) AS TotalPosts,
        SUM(COALESCE(PostDetails.Score, 0)) AS TotalScore 
    FROM 
        PostDetails
    GROUP BY 
        PostDetails.OwnerUserId
),
CombinedData AS (
    SELECT 
        U.DisplayName, 
        R.UserRank, 
        UPC.TotalPosts, 
        UPC.TotalScore,
        PD.Title,
        PD.CreationDate,
        PD.AcceptedAnswerId
    FROM 
        RankedUsers R
    JOIN 
        UserPostCounts UPC ON R.UserId = UPC.OwnerUserId
    LEFT JOIN 
        PostDetails PD ON PD.OwnerUserId = R.UserId
)
SELECT 
    CD.DisplayName,
    CD.UserRank,
    CD.TotalPosts,
    CD.TotalScore,
    CD.Title,
    CD.CreationDate,
    (SELECT COUNT(*) 
     FROM Votes V 
     WHERE V.PostId = CD.Title) AS VoteCount
FROM 
    CombinedData CD
WHERE 
    CD.TotalScore > 0
ORDER BY 
    CD.UserRank, 
    CD.TotalScore DESC
LIMIT 10;
