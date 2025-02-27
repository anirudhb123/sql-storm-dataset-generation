WITH RecursivePostCTE AS (
    SELECT
        P.Id,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.OwnerUserId,
        1 AS Level
    FROM
        Posts P
    WHERE
        P.ParentId IS NULL  -- Start with top-level questions
    UNION ALL
    SELECT
        P2.Id,
        P2.Title,
        P2.Body,
        P2.CreationDate,
        P2.ViewCount,
        P2.Score,
        P2.OwnerUserId,
        Level + 1
    FROM
        Posts P2
    INNER JOIN
        RecursivePostCTE R ON P2.ParentId = R.Id
),
PostVotes AS (
    SELECT
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM
        Votes
    GROUP BY
        PostId
),
PostHistoryStats AS (
    SELECT
        PH.PostId,
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM
        PostHistory PH
    WHERE
        PH.PostHistoryTypeId IN (4, 5, 24) -- Edit Title, Edit Body, Suggested Edit
    GROUP BY
        PH.PostId
)

SELECT
    P.Id AS PostId,
    P.Title,
    RP.ViewCount,
    RP.Score,
    COALESCE(PV.UpVotes, 0) AS TotalUpVotes,
    COALESCE(PV.DownVotes, 0) AS TotalDownVotes,
    COALESCE(PHS.EditCount, 0) AS TotalEdits,
    PHS.LastEditDate,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    R.Level AS PostLevel,
    CASE
        WHEN P.CreationDate < CURRENT_TIMESTAMP - INTERVAL '30 days' THEN 'Older Post'
        ELSE 'Recent Post'
    END AS PostAgeCategory
FROM
    RecursivePostCTE R
JOIN
    Posts P ON R.Id = P.Id
LEFT JOIN
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN
    PostVotes PV ON P.Id = PV.PostId
LEFT JOIN
    PostHistoryStats PHS ON P.Id = PHS.PostId
ORDER BY
    R.Level, P.ViewCount DESC, P.Score DESC;
