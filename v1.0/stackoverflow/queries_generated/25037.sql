WITH TagPostCounts AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    GROUP BY 
        T.Id, T.TagName
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
RecentPostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        RANK() OVER(PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT 
    U.DisplayName,
    U.Reputation,
    T.TagName,
    TPC.PostCount,
    UPS.TotalPosts,
    UPS.QuestionCount,
    UPS.AnswerCount,
    RPA.Title AS RecentPostTitle,
    RPA.CreationDate AS RecentPostDate
FROM 
    Users U 
JOIN 
    UserPostStats UPS ON U.Id = UPS.UserId
JOIN 
    TagPostCounts TPC ON TPC.PostCount > 0
LEFT JOIN 
    RecentPostActivity RPA ON U.Id = RPA.OwnerUserId AND RPA.PostRank = 1
ORDER BY 
    U.Reputation DESC, TPC.PostCount DESC;
