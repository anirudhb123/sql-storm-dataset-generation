WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
), 
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        RANK() OVER (ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalBounty,
    U.UpVotes,
    U.DownVotes,
    PP.PostId,
    PP.Title AS PopularPostTitle,
    PP.Score AS PostScore,
    PP.ViewCount AS PostViewCount
FROM 
    UserScore U
LEFT JOIN 
    PopularPosts PP ON U.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = PP.PostId)
WHERE 
    (U.Reputation >= 100 OR U.TotalBounty > 0) 
    AND (PP.ScoreRank <= 10 OR PP.Score IS NULL)
ORDER BY 
    U.Reputation DESC, U.DisplayName;


