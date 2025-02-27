
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalBounty,
        UpVotes,
        DownVotes,
        @rank:=IF(@prevTotalBounty = TotalBounty, @rank, @rank + 1) AS UserRank,
        @prevTotalBounty := TotalBounty
    FROM 
        UserActivity, (SELECT @rank := 0, @prevTotalBounty := NULL) AS vars
    ORDER BY 
        TotalBounty DESC, UpVotes DESC
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.AnswerCount,
        MAX(PH.CreationDate) AS LastEditDate,
        GROUP_CONCAT(DISTINCT T.TagName ORDER BY T.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '<>', numbers.n), '<>', -1)) AS TagName
         FROM 
             (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers 
         WHERE 
             CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '<>', '')) >= numbers.n - 1) T 
    ON TRUE
    WHERE 
        P.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.AnswerCount
)
SELECT 
    U.DisplayName,
    U.PostCount,
    U.TotalBounty,
    U.UpVotes,
    U.DownVotes,
    R.UserRank,
    A.PostId,
    A.Title,
    A.ViewCount,
    A.AnswerCount,
    A.LastEditDate,
    A.Tags
FROM 
    RankedUsers R
JOIN 
    UserActivity U ON R.UserId = U.UserId
LEFT JOIN 
    ActivePosts A ON A.LastEditDate = (SELECT MAX(AP.LastEditDate) FROM ActivePosts AP WHERE AP.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.UserId))
WHERE 
    R.UserRank <= 10
ORDER BY 
    U.TotalBounty DESC, U.UpVotes DESC;
