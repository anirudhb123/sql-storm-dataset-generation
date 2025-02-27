WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.PostTypeId = 1 -- Only questions
    GROUP BY P.Id, U.DisplayName, P.Title, P.CreationDate, P.ViewCount, P.Score, P.OwnerUserId
),
RecentEdits AS (
    SELECT 
        PH.PostId,
        PH.UserDisplayName,
        PH.CreationDate AS EditDate,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS EditRN
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6, 10, 11) -- Title edits, body edits, tag edits, closes, reopens
),
MostVotedPosts AS (
    SELECT 
        PostId,
        COUNT(*) AS VoteCount
    FROM Votes
    WHERE VoteTypeId IN (2, 3) -- Count upvotes and downvotes
    GROUP BY PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    COALESCE(RE.UserDisplayName, 'No Edits') AS LastEditedBy,
    COALESCE(RE.EditDate, 'No Edits') AS LastEditDate,
    RP.UpVotes,
    RP.DownVotes,
    M.VoteCount AS TotalVotes
FROM RankedPosts RP
LEFT JOIN RecentEdits RE ON RP.PostId = RE.PostId AND RE.EditRN = 1 -- Latest edit
LEFT JOIN MostVotedPosts M ON RP.PostId = M.PostId
WHERE RP.RN = 1 -- Only the latest post of each user
AND RP.Score > 0 -- Only questions with a positive score
ORDER BY RP.CreationDate DESC
LIMIT 10; -- Limit output for performance
