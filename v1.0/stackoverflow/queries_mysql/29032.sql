
WITH TagCounts AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1))
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 10  
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1  
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY QuestionCount DESC) AS UserRank
    FROM 
        UserActivity
    WHERE 
        QuestionCount > 5  
)
SELECT 
    T.Tag,
    T.PostCount,
    U.DisplayName AS TopUser,
    U.QuestionCount AS UserQuestionCount,
    U.UpVotes,
    U.DownVotes
FROM 
    TopTags T
JOIN 
    TopUsers U ON U.QuestionCount = (
        SELECT 
            MAX(QuestionCount) 
        FROM 
            TopUsers 
        WHERE 
            QuestionCount IN (
                SELECT 
                    QuestionCount 
                FROM 
                    UserActivity
            )
    )
ORDER BY 
    T.PostCount DESC, U.UpVotes DESC;
