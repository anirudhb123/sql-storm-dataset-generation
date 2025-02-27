WITH PostTagCounts AS (
    SELECT 
        PostId,
        COUNT(*) as TagCount
    FROM 
        Posts
    CROSS JOIN 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '> <')) AS Tag
    GROUP BY 
        PostId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(PC.TagCount) AS TotalTags
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostTagCounts PC ON P.Id = PC.PostId
    WHERE 
        U.Reputation > 1000 -- Only consider users with reputation greater than 1000
    GROUP BY 
        U.Id, U.DisplayName
),
RecentBadges AS (
    SELECT 
        B.UserId,
        ARRAY_AGG(B.Name ORDER BY B.Date DESC) AS RecentBadges
    FROM 
        Badges B
    WHERE 
        B.Date > NOW() - INTERVAL '1 year' -- Badges received in the last year
    GROUP BY 
        B.UserId
),
FinalStats AS (
    SELECT 
        UPS.UserId,
        UPS.DisplayName,
        UPS.TotalPosts,
        UPS.QuestionCount,
        UPS.AnswerCount,
        UPS.TotalTags,
        COALESCE(RB.RecentBadges, '{}') AS RecentBadges
    FROM 
        UserPostStats UPS
    LEFT JOIN 
        RecentBadges RB ON UPS.UserId = RB.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    QuestionCount,
    AnswerCount,
    TotalTags,
    RecentBadges
FROM 
    FinalStats
ORDER BY 
    TotalPosts DESC
LIMIT 10;
