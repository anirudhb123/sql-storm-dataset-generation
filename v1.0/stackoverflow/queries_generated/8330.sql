WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) -- Bounty Start or Close
    WHERE 
        U.Reputation >= 1000 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        TAGS.TagsArray
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT 
             PostId,
             STRING_AGG(TAG.TagName, ', ') AS TagsArray
         FROM 
             Posts P
         JOIN 
             UNNEST(string_to_array(P.Tags, '<>')) AS TAG(TagName) ON TRUE
         GROUP BY 
             PostId) TAGS ON P.Id = TAGS.PostId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.AnswerCount,
    U.QuestionCount,
    U.TotalBounty,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.TagsArray
FROM 
    UserStats U
INNER JOIN 
    Posts P ON U.UserId = P.OwnerUserId
WHERE 
    P.CreationDate > NOW() - INTERVAL '1 year'
ORDER BY 
    U.Reputation DESC, P.Score DESC
LIMIT 50;
