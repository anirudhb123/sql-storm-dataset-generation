WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.Score, 
        P.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= '2021-01-01'
),
PopularTags AS (
    SELECT 
        T.TagName, 
        COUNT(*) AS UsageCount
    FROM 
        Tags T 
    JOIN 
        Posts P ON T.Id = P.Id 
    GROUP BY 
        T.TagName
    ORDER BY 
        UsageCount DESC
    LIMIT 5
),
UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U 
    LEFT JOIN 
        Badges B ON U.Id = B.UserId 
    GROUP BY 
        U.Id, U.DisplayName
),
ClosedPosts AS (
    SELECT 
        P.Id AS ClosedPostId, 
        PH.CreationDate AS ClosedDate, 
        PH.UserDisplayName,
        PH.Comment 
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON P.Id = PH.PostId 
    WHERE 
        PH.PostHistoryTypeId = 10 
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        COALESCE(CommentCount, 0) AS TotalComments,
        COALESCE(VoteCount, 0) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
)
SELECT 
    RP.PostId, 
    RP.Title, 
    RP.CreationDate, 
    RP.Score, 
    RP.ViewCount, 
    PStats.TotalComments, 
    PStats.TotalVotes, 
    U.DisplayName AS TopUser,
    UB.BadgeCount,
    Closed.ClosedDate,
    CUM.TagName
FROM 
    RankedPosts RP
LEFT JOIN 
    PostStatistics PStats ON RP.PostId = PStats.PostId
LEFT JOIN 
    UserBadges UB ON UB.UserId = RP.PostId
LEFT JOIN 
    (SELECT 
         DISTINCT TagName 
     FROM 
         PopularTags 
     LIMIT 3) CUM ON TRUE
LEFT JOIN 
    ClosedPosts Closed ON Closed.ClosedPostId = RP.PostId
WHERE 
    RP.Rank <= 10
ORDER BY 
    RP.Score DESC, 
    RP.ViewCount DESC;
