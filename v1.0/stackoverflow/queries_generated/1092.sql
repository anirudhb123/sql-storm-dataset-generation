WITH UserReputation AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CreationDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
), 
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        P.AnswerCount,
        COALESCE(P.ClosedDate, '1899-12-30'::timestamp) AS ClosedDate,
        ARRAY_AGG(DISTINCT T.TagName) AS Tags
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN LATERAL unnest(substring(P.Tags, 2, length(P.Tags) - 2)::text[]) AS T(TagName) ON true
    WHERE P.PostTypeId = 1 -- Consider only questions
    GROUP BY P.Id, U.DisplayName, P.Title, P.CreationDate, P.Score, P.AnswerCount, P.ClosedDate
), 
VoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
)
SELECT 
    UR.DisplayName AS UserDisplayName,
    UR.Reputation AS UserReputation,
    PD.Title AS PostTitle,
    PD.CreationDate AS PostCreationDate,
    (PD.Score + COALESCE(VS.UpVotes, 0) - COALESCE(VS.DownVotes, 0)) AS NetScore,
    PD.AnswerCount AS TotalAnswers,
    PD.ClosedDate,
    PD.Tags
FROM UserReputation UR
INNER JOIN PostDetails PD ON PD.OwnerDisplayName = UR.DisplayName
LEFT JOIN VoteSummary VS ON PD.PostId = VS.PostId
WHERE UR.Rank <= 100
AND (PD.ClosedDate IS NULL OR PD.ClosedDate >= NOW() - interval '1 year')
ORDER BY UR.Reputation DESC, NetScore DESC
LIMIT 50;

