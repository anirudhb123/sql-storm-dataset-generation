
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        PostTypeId,
        Id AS PostId,
        OwnerUserId
    FROM 
        Posts
    JOIN 
        (SELECT @rownum := @rownum + 1 AS n FROM 
         (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
          UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) 
          t1, (SELECT @rownum := 0) t2) n
    WHERE 
        PostTypeId = 1 
        AND n.n <= (LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', '')) + 1)
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS QuestionCount,
        COUNT(DISTINCT OwnerUserId) AS UserCount
    FROM 
        TagCounts
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        QuestionCount,
        UserCount,
        @rank := @rank + 1 AS Rank
    FROM 
        TagStatistics, (SELECT @rank := 0) r
    WHERE 
        QuestionCount > 10 
    ORDER BY 
        QuestionCount DESC, UserCount DESC
),
UserTagEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        T.Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    JOIN 
        TagCounts T ON P.Id = T.PostId
    GROUP BY 
        U.Id, U.DisplayName, T.Tag
),
EngagementRankings AS (
    SELECT 
        UserId, 
        DisplayName, 
        Tag, 
        PostCount,
        QuestionCount,
        AnswerCount,
        @tagRank := IF(@currentTag = Tag, @tagRank + 1, 1) AS TagRank,
        @currentTag := Tag
    FROM 
        UserTagEngagement, (SELECT @tagRank := 0, @currentTag := '') r
    ORDER BY 
        Tag, PostCount DESC
)

SELECT 
    E.Tag, 
    E.DisplayName, 
    E.PostCount,
    E.QuestionCount,
    E.AnswerCount,
    T.QuestionCount AS TotalQuestionsForTag,
    T.UserCount AS TotalUsersForTag,
    CASE 
        WHEN E.TagRank <= 5 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributionLevel
FROM 
    EngagementRankings E
JOIN 
    TopTags T ON E.Tag = T.Tag
WHERE 
    E.TagRank <= 10 
ORDER BY 
    E.Tag, E.PostCount DESC;
