WITH RecursivePostCTE AS (
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        P.OwnerUserId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Starting with Questions

    UNION ALL

    SELECT 
        P2.Id AS PostId,
        P2.ParentId,
        P2.OwnerUserId,
        RPC.Level + 1
    FROM 
        Posts P2
    INNER JOIN 
        RecursivePostCTE RPC ON P2.ParentId = RPC.PostId
)

SELECT 
    U.Id AS UserId,
    U.DisplayName AS UserDisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS QuestionCount,
    COUNT(DISTINCT A.Id) AS AnswerCount,
    SUM(COALESCE(V.UpVotes, 0)) AS TotalUpVotes,
    SUM(COALESCE(V.DownVotes, 0)) AS TotalDownVotes,
    AVG(COALESCE(CAST(PH.UserId AS float) / NULLIF(PH.RevisionGUID, '') , 0)) AS AverageHistoryPerPost,
    STRING_AGG(DISTINCT T.TagName, ', ') AS TagsUsed,
    MAX(P.LastActivityDate) AS LastActiveDate
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 -- Join on Questions
LEFT JOIN 
    Posts A ON P.Id = A.ParentId -- Join on Answers
LEFT JOIN 
    Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 3) -- Upvotes and Downvotes
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId 
LEFT JOIN 
    LATERAL (
        SELECT 
            T.TagName
        FROM 
            Tags T
        WHERE 
            T.Id IN (
                SELECT UNNEST(string_to_array(P.Tags, ','))::int
            )
    ) AS T ON TRUE 
LEFT JOIN 
    RecursivePostCTE RPC ON U.Id = RPC.OwnerUserId
WHERE 
    U.Reputation > 1000 -- Only consider users with a reputation above 1000
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
HAVING
    COUNT(DISTINCT P.Id) > 0 -- Users must have at least one Question
ORDER BY 
    TotalUpVotes DESC, LastActiveDate DESC
LIMIT 50;
