WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  -- Only questions
),
PopularPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        Author
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostDetails AS (
    SELECT 
        PP.PostId,
        PP.Title,
        PP.CreationDate,
        PP.Score,
        PP.ViewCount,
        PP.AnswerCount,
        PP.CommentCount,
        PP.Author,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(VoteCount.VoteUpCount, 0) AS VoteUpCount,
        COALESCE(VoteCount.VoteDownCount, 0) AS VoteDownCount
    FROM 
        PopularPosts PP
    LEFT JOIN 
        Comments C ON PP.PostId = C.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS VoteUpCount,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS VoteDownCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) VoteCount ON PP.PostId = VoteCount.PostId
    GROUP BY
        PP.PostId, PP.Title, PP.CreationDate, PP.Score, PP.ViewCount, PP.AnswerCount, PP.CommentCount, PP.Author
),
PostHistoryOverview AS (
    SELECT 
        PH.PostId,
        PHT.Name AS ChangeType,
        PH.CreationDate AS ChangeDate,
        PH.UserDisplayName,
        PH.Comment
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PH.PostId IN (SELECT PostId FROM PostDetails)
),
RecentTags AS (
    SELECT
        T.TagName,
        P.Id AS PostId,
        P.Title
    FROM 
        Posts P
    CROSS JOIN 
        UNNEST(string_to_array(P.Tags, ',')) AS T(TagName)
    WHERE 
        P.Id IN (SELECT PostId FROM PostDetails)
)

SELECT 
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.ViewCount,
    PD.AnswerCount,
    PD.CommentCount,
    PD.Author,
    COALESCE(array_agg(DISTINCT RT.TagName) FILTER (WHERE RT.TagName IS NOT NULL), '{}') AS Tags,
    ARRAY(
        SELECT 
            JSON_BUILD_OBJECT(
                'ChangeType', PHO.ChangeType,
                'ChangeDate', PHO.ChangeDate,
                'User', PHO.UserDisplayName,
                'Comment', PHO.Comment
            )
        FROM 
            PostHistoryOverview PHO
        WHERE 
            PHO.PostId = PD.PostId
    ) AS ChangeHistory
FROM 
    PostDetails PD
LEFT JOIN 
    RecentTags RT ON PD.PostId = RT.PostId
GROUP BY 
    PD.PostId, PD.Title, PD.CreationDate, PD.Score, PD.ViewCount, PD.AnswerCount, PD.CommentCount, PD.Author
ORDER BY 
    PD.Score DESC;
