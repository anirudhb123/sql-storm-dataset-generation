WITH TagStatistics AS (
    SELECT
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        COALESCE(AVG(P.Score), 0) AS AvgScore,
        COUNT(DISTINCT U.Id) AS UniqueUserCount,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS UserList
    FROM
        Tags T
    LEFT JOIN
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%') -- Ensuring tag is within the tag string
    LEFT JOIN
        Users U ON P.OwnerUserId = U.Id
    GROUP BY
        T.TagName
),

PostInteractions AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    WHERE
        P.PostTypeId = 1 -- Only for Questions
    GROUP BY
        P.Id, P.Title
),

RecentActivity AS (
    SELECT
        U.DisplayName AS Author,
        P.Title,
        P.CreationDate,
        PH.CreationDate AS HistoryDate,
        pst.Name AS PostType,   
        PH.Comment AS EditComment
    FROM
        Posts P
    JOIN
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN
        PostTypes pst ON P.PostTypeId = pst.Id
    WHERE
        P.CreationDate >= NOW() - INTERVAL '30 days'
)

SELECT
    TS.TagName,
    TS.PostCount,
    TS.TotalViews,
    TS.AvgScore,
    TS.UniqueUserCount,
    TS.UserList,
    PI.PostId,
    PI.Title AS PostTitle,
    PI.CommentCount,
    PI.VoteCount,
    PI.UpVoteCount,
    PI.DownVoteCount,
    RA.Author,
    RA.HistoryDate,
    RA.EditComment
FROM 
    TagStatistics TS
LEFT JOIN 
    PostInteractions PI ON TS.TagName IN (SELECT UNNEST(string_to_array(PI.Tags, ', '))) 
LEFT JOIN 
    RecentActivity RA ON PI.PostId = RA.PostId
ORDER BY 
    TS.TotalViews DESC, 
    TS.PostCount DESC, 
    PI.VoteCount DESC;
