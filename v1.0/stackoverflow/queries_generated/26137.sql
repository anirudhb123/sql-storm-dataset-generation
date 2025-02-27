WITH TagDetails AS (
    SELECT
        P.Id AS PostId,
        COUNT(DISTINCT T.TagName) AS TagCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagsList
    FROM
        Posts P
    LEFT JOIN
        UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')) AS TagName ON TRUE
    JOIN
        Tags T ON T.TagName = TagName
    WHERE
        P.PostTypeId = 1 -- Only questions
    GROUP BY
        P.Id
),
UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.UpVotes,
        U.DownVotes
    FROM
        Users U
    WHERE
        U.Reputation > 1000 -- Users with a reputation greater than 1000
),
PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        PH.CreationDate AS LastEditDate,
        PH.UserDisplayName AS LastEditor,
        T.TagsList,
        UR.DisplayName AS OwnerDisplayName,
        UR.Reputation AS OwnerReputation
    FROM
        Posts P
    LEFT JOIN
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 5 -- Last edit body
    LEFT JOIN
        UserReputation UR ON P.OwnerUserId = UR.UserId
    LEFT JOIN
        TagDetails T ON P.Id = T.PostId
    WHERE
        P.Score > 0 -- Only posts with a positive score
)
SELECT
    PS.PostId,
    PS.Title,
    PS.Body,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.LastEditDate,
    PS.LastEditor,
    PS.TagsList,
    PS.OwnerDisplayName,
    PS.OwnerReputation,
    COALESCE(SUM(V.BountyAmount) FILTER (WHERE V.CreationDate > NOW() - INTERVAL '30 days'), 0) AS RecentBounties
FROM
    PostStats PS
LEFT JOIN
    Votes V ON PS.PostId = V.PostId AND V.CreationDate > NOW() - INTERVAL '30 days' AND V.VoteTypeId = 8 -- Bounty Start
GROUP BY
    PS.PostId, PS.Title, PS.Body, PS.ViewCount, PS.AnswerCount, PS.CommentCount, PS.LastEditDate, PS.LastEditor, PS.TagsList, PS.OwnerDisplayName, PS.OwnerReputation
ORDER BY
    PS.ViewCount DESC
LIMIT 10;
