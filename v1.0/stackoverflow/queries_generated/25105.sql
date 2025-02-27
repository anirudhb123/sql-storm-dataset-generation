WITH PostTagCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(DISTINCT T.TagName) AS UniqueTagCount
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON POSITION(CONCAT('<', T.TagName, '>') IN P.Tags) > 0
    WHERE 
        P.PostTypeId = 1 -- only questions
    GROUP BY 
        P.Id
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(COALESCE(B.Class = 1, 0)::int) AS GoldBadgeCount,
        SUM(COALESCE(B.Class = 2, 0)::int) AS SilverBadgeCount,
        SUM(COALESCE(B.Class = 3, 0)::int) AS BronzeBadgeCount,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        AVG(UniqueTagCount) AS AvgTagsPerQuestion
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    LEFT JOIN 
        PostTagCounts TC ON TC.PostId = P.Id
    GROUP BY 
        U.Id
),
MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        GoldBadgeCount,
        SilverBadgeCount,
        BronzeBadgeCount,
        TotalScore,
        AvgTagsPerQuestion,
        ROW_NUMBER() OVER (ORDER BY QuestionCount DESC) AS Rank
    FROM 
        UserPostStats
    WHERE 
        QuestionCount > 0
)
SELECT 
    Rank,
    DisplayName,
    QuestionCount,
    GoldBadgeCount,
    SilverBadgeCount,
    BronzeBadgeCount,
    TotalScore,
    AvgTagsPerQuestion
FROM 
    MostActiveUsers
WHERE 
    Rank <= 10
ORDER BY 
    TotalScore DESC;
