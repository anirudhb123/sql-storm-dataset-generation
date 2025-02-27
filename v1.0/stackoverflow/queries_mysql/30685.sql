
WITH RecursiveUserContribution AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(P.Id) AS PostCount, 
        SUM(V.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(U.LastAccessDate, U.CreationDate) AS LastActiveDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.LastAccessDate, U.CreationDate
),
UserBadges AS (
    SELECT 
        B.UserId, 
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        GROUP_CONCAT(T.TagName ORDER BY T.TagName SEPARATOR ', ') AS TagsList
    FROM 
        Posts P
    CROSS JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
               UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
         WHERE CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1) T
    GROUP BY 
        P.Id
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UC.PostCount, 0) AS TotalPosts,
    COALESCE(UC.Questions, 0) AS TotalQuestions,
    COALESCE(UC.Answers, 0) AS TotalAnswers,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    UC.TotalBounties,
    UC.LastActiveDate,
    PT.TagsList
FROM 
    Users U
LEFT JOIN 
    RecursiveUserContribution UC ON U.Id = UC.UserId
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    PostTags PT ON P.Id = PT.PostId
WHERE 
    (UC.Rank IS NULL OR UC.Rank <= 10)
ORDER BY 
    U.Reputation DESC, 
    UC.TotalBounties DESC;
