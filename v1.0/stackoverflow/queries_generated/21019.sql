WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        TotalScore,
        AvgViewCount,
        LastPostDate,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
    WHERE 
        LastPostDate >= NOW() - INTERVAL '1 month'
)
SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.QuestionCount,
    U.AnswerCount,
    COALESCE(CASE 
        WHEN U.AnswerCount = 0 THEN 'No Answers' 
        ELSE FORMAT('%d', U.AnswerCount) 
    END, 'N/A') AS AnswerStatus,
    U.TotalScore,
    U.AvgViewCount,
    U.ScoreRank,
    A.TagsUsed,
    A.BadgesEarned
FROM 
    ActiveUsers U
LEFT JOIN (
    SELECT 
        UserId,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagsUsed,
        COUNT(DISTINCT B.Id) AS BadgesEarned
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Tags T ON POSITION(T.TagName IN P.Tags) > 0
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        UserId
) A ON U.UserId = A.UserId
WHERE 
    U.TotalPosts > 0 
    AND U.ScoreRank <= 10
ORDER BY 
    U.TotalScore DESC, 
    U.LastPostDate DESC
LIMIT 50;

-- Additional query to find users with a peculiar history of posts closed recently
WITH RecentCloseHistory AS (
    SELECT 
        P.OwnerUserId,
        COUNT(H.Id) AS ClosedPostsCount,
        MAX(H.CreationDate) AS LastCloseDate
    FROM 
        PostHistory H
    INNER JOIN 
        Posts P ON H.PostId = P.Id
    WHERE 
        H.PostHistoryTypeId = 10 
        AND H.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Location,
    U.Reputation,
    R.ClosedPostsCount,
    R.LastCloseDate,
    CASE 
        WHEN R.ClosedPostsCount > 5 THEN 'Frequent Closer'
        ELSE 'Infrequent Closer'
    END AS CloseActivityType
FROM 
    Users U
INNER JOIN 
    RecentCloseHistory R ON U.Id = R.OwnerUserId
WHERE 
    U.Reputation < 500
    AND R.ClosedPostsCount IS NOT NULL
ORDER BY 
    R.ClosedPostsCount DESC
LIMIT 20;
