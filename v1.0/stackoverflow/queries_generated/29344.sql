WITH TagsCTE AS (
    SELECT 
        TagName, 
        COUNT(*) AS PostCount,
        STRING_AGG(DISTINCT TagName, ', ') AS AllTags 
    FROM 
        Tags 
    JOIN 
        Posts ON Tags.Id = Posts.Id 
    WHERE 
        Posts.ViewCount > 100 
    GROUP BY 
        TagName
),

UserActivityCTE AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),

UserScoresCTE AS (
    SELECT 
        UserId,
        DisplayName,
        (QuestionCount * 2) + (AnswerCount * 3) + (CommentCount * 1) + (BadgeCount * 5) AS Score 
    FROM 
        UserActivityCTE
),

RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Score,
        RANK() OVER (ORDER BY Score DESC) AS UserRank
    FROM 
        UserScoresCTE
)

SELECT 
    R.DisplayName,
    R.Score,
    R.UserRank,
    T.AllTags,
    T.PostCount
FROM 
    RankedUsers R
LEFT JOIN 
    TagsCTE T ON R.UserId = (SELECT OwnerUserId FROM Posts WHERE Tags LIKE '%' || T.TagName || '%')
WHERE 
    R.UserRank <= 10
ORDER BY 
    R.UserRank;
