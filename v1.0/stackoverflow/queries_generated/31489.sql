WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class,
        B.Date,
        ROW_NUMBER() OVER(PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
),

ActiveUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        LastAccessDate,
        Views,
        UpVotes,
        DownVotes,
        CASE 
            WHEN Views IS NULL THEN 0 
            ELSE Views 
        END AS SafeViews
    FROM 
        Users
    WHERE 
        LastAccessDate >= NOW() - INTERVAL '1 year'
),

PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.LastActivityDate,
        RANK() OVER (ORDER BY P.Score DESC, P.ViewCount DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1
        AND P.CreationDate >= NOW() - INTERVAL '1 year'
),

TopTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10
)

SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    U.SafeViews,
    PB.BadgeName,
    PB.Class,
    PP.Title AS PopularPostTitle,
    PP.Score AS PopularPostScore,
    PP.ViewCount AS PopularPostViewCount,
    TT.TagName AS TopTag,
    TT.PostCount
FROM 
    ActiveUsers U
LEFT JOIN 
    UserBadges PB ON U.Id = PB.UserId AND PB.BadgeRank = 1
LEFT JOIN 
    PopularPosts PP ON PP.PostId IN (SELECT PostId FROM Votes V WHERE V.UserId = U.Id)
LEFT JOIN 
    TopTags TT ON TT.TagName IN (SELECT unnest(string_to_array(PP.Title, ' ')))
WHERE 
    U.Reputation > 100
ORDER BY 
    U.Reputation DESC
LIMIT 100;

