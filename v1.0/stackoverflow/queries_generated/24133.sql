WITH UserBadges AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Date) AS LastBadgeDate
    FROM
        Users U
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id
),
PostDetails AS (
    SELECT
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        P.Title,
        P.Body,
        P.CreationDate,
        COALESCE(COUNT(DISTINCT C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVoteCount, 
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVoteCount
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    WHERE
        P.CreationDate BETWEEN '2022-01-01' AND NOW()
    GROUP BY
        P.Id
),
PostHistoryInfo AS (
    SELECT
        PH.PostId,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN PH.PostHistoryTypeId = 11 THEN PH.CreationDate END) AS ReopenedDate
    FROM
        PostHistory PH
    GROUP BY
        PH.PostId
),
AggregatePostData AS (
    SELECT
        PD.PostId,
        PD.OwnerUserId,
        PD.Title,
        PD.CommentCount,
        PD.UpVoteCount,
        PD.DownVoteCount,
        PH.ClosedDate,
        PH.ReopenedDate,
        U.DisplayName,
        U.Reputation,
        (RANK() OVER (ORDER BY PD.UpVoteCount DESC)) AS UpVoteRank
    FROM
        PostDetails PD
    JOIN
        Users U ON PD.OwnerUserId = U.Id
    LEFT JOIN
        PostHistoryInfo PH ON PD.PostId = PH.PostId
)
SELECT
    APD.PostId,
    APD.Title,
    APD.CommentCount,
    APD.UpVoteCount,
    APD.DownVoteCount,
    APD.ClosedDate,
    APD.ReopenedDate,
    APD.DisplayName AS OwnerDisplayName,
    APD.Reputation,
    CASE 
        WHEN APD.ClosedDate IS NOT NULL AND APD.ReopenedDate IS NULL THEN 'Closed'
        WHEN APD.ReopenedDate IS NOT NULL THEN 'Reopened'
        WHEN APD.CommentCount > 0 THEN 'Active'
        ELSE 'Idle'
    END AS PostStatus,
    COALESCE(UB.BadgeCount, 0) AS UserBadgeCount,
    COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostsCount,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
FROM
    AggregatePostData APD
LEFT JOIN
    UserBadges UB ON APD.OwnerUserId = UB.UserId
LEFT JOIN
    PostLinks PL ON APD.PostId = PL.PostId
LEFT JOIN
    Tags T ON T.ExcerptPostId = APD.PostId
GROUP BY
    APD.PostId, APD.Title, APD.CommentCount, APD.UpVoteCount, APD.DownVoteCount,
    APD.ClosedDate, APD.ReopenedDate, APD.DisplayName, APD.Reputation
ORDER BY
    UpVoteRank ASC, APD.CommentCount DESC
LIMIT 100 OFFSET 0;
