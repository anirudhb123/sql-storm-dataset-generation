
WITH TagCounts AS (
    SELECT 
        TRIM(REGEXP_REPLACE(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1), '<[^>]+', '')) AS TagName, 
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostsCount, 
        UpVotes, 
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserReputation
)
SELECT 
    TT.TagName,
    TT.PostCount,
    TU.DisplayName AS TopUserName,
    TU.Reputation AS TopUserReputation,
    TU.PostsCount AS TopUserPosts,
    TU.UpVotes AS TopUserUpVotes,
    TU.DownVotes AS TopUserDownVotes
FROM 
    TopTags TT
JOIN 
    TopUsers TU ON TT.TagRank = 1
WHERE 
    TU.PostsCount > 5
ORDER BY 
    TT.PostCount DESC, TU.Reputation DESC;
