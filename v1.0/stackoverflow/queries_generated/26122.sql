WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        AVG(P.Score) AS AverageScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%' 
    GROUP BY 
        T.TagName
),
UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
TopTags AS (
    SELECT 
        TagName,
        TotalViews,
        AverageScore
    FROM 
        TagStatistics
    WHERE 
        PostCount > 0
    ORDER BY 
        TotalViews DESC
    LIMIT 5
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.CreationDate AS AccountCreationDate,
    UBadge.GoldBadges,
    UBadge.SilverBadges,
    UBadge.BronzeBadges,
    PAc.PostId,
    PAc.Title,
    PAc.CreationDate,
    PAc.Score,
    PAc.CommentCount,
    PAc.UpVotes,
    PAc.DownVotes,
    TT.TagName,
    TT.TotalViews,
    TT.AverageScore
FROM 
    Users U
JOIN 
    UserBadgeCounts UBadge ON U.Id = UBadge.UserId
JOIN 
    PostActivity PAc ON U.Id = PAc.UserId
JOIN 
    TopTags TT ON PAc.Tags LIKE '%' || TT.TagName || '%'
WHERE 
    U.Reputation >= 100
ORDER BY 
    U.Reputation DESC, 
    PAc.Score DESC;
