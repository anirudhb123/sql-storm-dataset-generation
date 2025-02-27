WITH TagCounts AS (
    SELECT
        UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    WHERE
        PostTypeId = 1
    GROUP BY
        TagName
),

UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
),

PostDetails AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        COALESCE(A.DisapprovedReason, 'None') AS DisapprovedReason,
        U.DisplayName AS Author,
        UC.UserId AS ClosedByUser,
        COUNT(C.Id) AS CommentCount
    FROM
        Posts P
    LEFT JOIN
        (SELECT PostId, MIN(CloseReasonId) AS DisapprovedReason FROM PostHistory WHERE PostHistoryTypeId = 10 GROUP BY PostId) A ON P.Id = A.PostId
    LEFT JOIN
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    LEFT JOIN
        Users UC ON PH.UserId = UC.Id
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    WHERE
        P.PostTypeId = 1
    GROUP BY
        P.Id, P.Title, P.Body, P.CreationDate, A.DisapprovedReason, U.DisplayName, UC.UserId
)

SELECT
    TC.TagName,
    TC.PostCount,
    U.DisplayName AS AuthorDisplayName,
    U.Reputation AS AuthorReputation,
    PD.PostId,
    PD.Title,
    PD.Body,
    PD.CreationDate,
    PD.DisapprovedReason,
    COALESCE(PD.ClosedByUser, 'Open') AS ClosedByUser,
    PD.CommentCount,
    U.TotalUpVotes,
    U.TotalDownVotes
FROM
    TagCounts TC
JOIN
    Posts P ON P.Tags LIKE CONCAT('%<', TC.TagName, '>%')
JOIN
    UserReputation U ON P.OwnerUserId = U.UserId
JOIN
    PostDetails PD ON PD.PostId = P.Id
ORDER BY
    TC.PostCount DESC, U.Reputation DESC, PD.CreationDate DESC;
