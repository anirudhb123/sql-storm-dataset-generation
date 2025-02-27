WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Score, 
        P.ViewCount, 
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore,
        RANK() OVER (ORDER BY P.ViewCount DESC) AS RankView
    FROM 
        Posts P 
    WHERE 
        P.CreationDate >= (CURRENT_DATE - INTERVAL '1 year') 
        AND P.Score IS NOT NULL
),
TopPosts AS (
    SELECT 
        RP.*,
        (SELECT COUNT(*) 
         FROM Comments C 
         WHERE C.PostId = RP.PostId) AS CommentCount
    FROM 
        RankedPosts RP
    WHERE 
        RP.RankScore <= 5 -- Top 5 scores per post type
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT PH.Id) AS HistoryCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        PostHistory PH ON U.Id = PH.UserId
    GROUP BY 
        U.Id, U.Reputation
),
ActiveUsers AS (
    SELECT 
        UA.UserId, 
        UA.Reputation, 
        UA.UpVotes, 
        UA.DownVotes, 
        UA.BadgeCount
    FROM 
        UserActivity UA
    WHERE 
        UA.Reputation > 1000 
        AND UA.BadgeCount > 0
),
PostAnalytics AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.Score,
        TP.ViewCount,
        TP.CommentCount,
        UA.UserId AS TopUserId,
        UA.Reputation AS TopUserReputation,
        NTILE(4) OVER (ORDER BY TP.Score DESC) AS ScoreQuartile
    FROM 
        TopPosts TP
    LEFT JOIN 
        ActiveUsers UA ON UA.UpVotes = (
            SELECT MAX(UpVotes) 
            FROM UserActivity 
            WHERE UserId IN (
                SELECT OwnerUserId 
                FROM Posts p 
                WHERE p.Id = TP.PostId
            )
        )
)
SELECT 
    PA.PostId,
    PA.Title,
    PA.Score,
    PA.ViewCount,
    PA.CommentCount,
    PA.TopUserId,
    PA.TopUserReputation,
    PA.ScoreQuartile,
    CASE 
        WHEN PA.CommentCount > 5 THEN 'Highly Discussed'
        WHEN PA.CommentCount IS NULL THEN 'No Comments'
        ELSE 'Moderately Discussed'
    END AS DiscussionLevel,
    (SELECT STRING_AGG(DISTINCT T.TagName, ', ') 
     FROM Tags T 
     WHERE T.WikiPostId = PA.PostId) AS AssociatedTags
FROM 
    PostAnalytics PA
WHERE 
    PA.ScoreQuartile = 1 
ORDER BY 
    PA.Score DESC, PA.ViewCount DESC;
