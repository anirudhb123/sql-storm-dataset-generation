
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1        
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        PostCount,
        @rank := @rank + 1 AS Rank
    FROM 
        TagCounts, (SELECT @rank := 0) r
    WHERE 
        PostCount > 1
    ORDER BY 
        PostCount DESC
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 6 THEN 1 ELSE 0 END), 0) AS CloseVotes,
        COUNT(DISTINCT P.Id) AS QuestionPosts
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    GROUP BY 
        U.Id, U.DisplayName
),
MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        CloseVotes,
        QuestionPosts,
        @activity_rank := @activity_rank + 1 AS ActivityRank
    FROM 
        UserStatistics, (SELECT @activity_rank := 0) r
    ORDER BY 
        QuestionPosts DESC, UpVotes DESC
)
SELECT 
    T.Tag,
    T.PostCount,
    U.DisplayName AS ActiveUser,
    U.UpVotes,
    U.DownVotes,
    U.CloseVotes
FROM 
    TopTags T
LEFT JOIN 
    MostActiveUsers U ON U.ActivityRank = 1
ORDER BY 
    T.PostCount DESC, U.UpVotes DESC;
