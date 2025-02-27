
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS ClosedPosts,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS ReopenedPosts
    FROM 
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
UserStatistics AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        Upvotes,
        Downvotes,
        ClosedPosts,
        ReopenedPosts,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN Reputation > 5000 THEN 1 ELSE 0 END ORDER BY PostCount DESC) AS HighReputationPostRank
    FROM UserReputation
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(U.PostCount, 0) AS TotalPosts,
    COALESCE(U.Upvotes - U.Downvotes, 0) AS NetVotes,
    U.ReopenedPosts,
    (SELECT GROUP_CONCAT(DISTINCT T.TagName SEPARATOR ', ') 
     FROM Posts P 
     JOIN (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', numbers.n), ',', -1)) AS Tag
           FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
                 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
           WHERE CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, ',', '')) >= numbers.n-1) TagsList
     JOIN Tags T ON TagsList.Tag = T.TagName
     WHERE P.OwnerUserId = U.UserId) AS TagsUsed,
    CASE 
        WHEN U.Reputation > 10000 THEN 'Top Contributor' 
        WHEN U.Reputation > 5000 THEN 'Experienced' 
        ELSE 'New User' 
    END AS UserCategory
FROM 
    UserStatistics U
WHERE 
    U.ReputationRank <= 10 
    OR U.HighReputationPostRank <= 5 
ORDER BY 
    U.Reputation DESC, U.DisplayName
LIMIT 10 OFFSET 5;
