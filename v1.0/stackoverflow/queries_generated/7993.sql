WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        COUNT(CM.Id) AS CommentsCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments CM ON P.Id = CM.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        ARRAY_AGG(DISTINCT T.TagName) AS Tags,
        PH.UserDisplayName AS LastEditor,
        PH.CreationDate AS LastEditDate
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6) 
    LEFT JOIN 
        LATERAL unnest(string_to_array(P.Tags, '><')) AS tag(TagName) ON true
    GROUP BY 
        P.Id, PH.UserDisplayName, PH.CreationDate
),
Ranking AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.PostsCount,
        UA.QuestionsCount,
        UA.AnswersCount,
        UA.CommentsCount,
        UA.GoldBadges,
        UA.SilverBadges,
        UA.BronzeBadges,
        UA.UpVotes,
        UA.DownVotes,
        ROW_NUMBER() OVER (ORDER BY UA.Reputation DESC) AS Rank
    FROM 
        UserActivity UA
)
SELECT 
    R.Rank,
    R.DisplayName,
    R.PostsCount,
    R.QuestionsCount,
    R.AnswersCount,
    R.CommentsCount,
    R.GoldBadges,
    R.SilverBadges,
    R.BronzeBadges,
    R.UpVotes,
    R.DownVotes,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.Tags,
    PS.LastEditor,
    PS.LastEditDate
FROM 
    Ranking R
LEFT JOIN 
    PostStatistics PS ON R.UserId = PS.LastEditor
ORDER BY 
    R.Rank, PS.CreationDate DESC;
