WITH PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.LastActivityDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagList
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON A.ParentId = P.Id
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(P.Tags, 2, LENGTH(P.Tags)-2), '><') AS TagArray ON TRUE
    LEFT JOIN 
        Tags T ON T.TagName = TagArray
    WHERE 
        P.PostTypeId = 1 -- only for Questions
    GROUP BY 
        P.Id, P.Title, P.Body, U.DisplayName, P.CreationDate, P.LastActivityDate
),
PostStatistics AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.OwnerDisplayName,
        PD.CreationDate,
        PD.LastActivityDate,
        PD.CommentCount,
        PD.AnswerCount,
        COALESCE(V.UpVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes,
        PD.TagList
    FROM 
        PostDetails PD
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) V ON PD.PostId = V.PostId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.OwnerDisplayName,
    EXTRACT(EPOCH FROM (PS.LastActivityDate - PS.CreationDate)) AS ActivityDurationInSeconds,
    PS.AnswerCount,
    PS.CommentCount,
    PS.UpVotes,
    PS.DownVotes,
    PS.TagList,
    CASE 
        WHEN PS.CommentCount > 10 THEN 'Highly Engaged'
        WHEN PS.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PostStatistics PS
ORDER BY 
    PS.AnswerCount DESC, PS.LastActivityDate DESC
LIMIT 100;
