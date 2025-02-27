
WITH TagCount AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 + 1 AS n
         FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
              (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) numbers 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1))
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        @rank := IF(@prev = PostCount, @rank, @rank + 1) AS Rank,
        @prev := PostCount
    FROM 
        TagCount, (SELECT @rank := 0, @prev := NULL) r
    WHERE 
        PostCount > 10 
    ORDER BY 
        PostCount DESC
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount, 
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount 
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        U.Id, U.DisplayName
),
TagEngagement AS (
    SELECT 
        T.TagName,
        SUM(UE.QuestionCount) AS TotalQuestions,
        SUM(UE.CommentCount) AS TotalComments,
        SUM(UE.UpVoteCount) AS TotalUpVotes,
        SUM(UE.DownVoteCount) AS TotalDownVotes
    FROM 
        TopTags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%') 
    JOIN 
        UserEngagement UE ON P.OwnerUserId = UE.UserId
    GROUP BY 
        T.TagName
)
SELECT 
    TE.TagName,
    TE.TotalQuestions,
    TE.TotalComments,
    TE.TotalUpVotes,
    TE.TotalDownVotes,
    CASE 
        WHEN TE.TotalQuestions > 100 THEN 'Very Active'
        WHEN TE.TotalQuestions BETWEEN 50 AND 100 THEN 'Active'
        ELSE 'Less Active'
    END AS EngagementLevel
FROM 
    TagEngagement TE
WHERE 
    TE.TotalQuestions > 0
ORDER BY 
    TE.TotalQuestions DESC;
