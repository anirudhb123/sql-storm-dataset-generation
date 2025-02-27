WITH TagStats AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AvgScore
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only questions
    GROUP BY 
        Tag
),

UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),

PostActivityStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes, -- Counting upvotes
        SUM(V.VoteTypeId = 3) AS DownVotes -- Counting downvotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1  -- Only questions
    GROUP BY 
        P.Id, P.OwnerDisplayName
)

SELECT 
    T.Tag, 
    T.PostCount, 
    T.TotalViews, 
    T.AvgScore,
    U.DisplayName AS UserName,
    U.BadgeCount, 
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    P.OwnerDisplayName AS QuestionAuthor,
    P.CommentCount,
    P.UpVotes,
    P.DownVotes
FROM 
    TagStats T
JOIN 
    UserBadgeCounts U ON U.UserId IN (
        SELECT OwnerUserId
        FROM Posts
        WHERE Tags LIKE '%' || T.Tag || '%'
    )
JOIN 
    PostActivityStats P ON P.PostId IN (
        SELECT Id 
        FROM Posts 
        WHERE Tags LIKE '%' || T.Tag || '%'
    )
ORDER BY 
    T.PostCount DESC, T.TotalViews DESC, U.BadgeCount DESC;
