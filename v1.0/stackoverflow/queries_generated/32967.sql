WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.ParentId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Start from Questions
    UNION ALL
    SELECT 
        P2.Id AS PostId,
        P2.Title,
        P2.OwnerUserId,
        P2.CreationDate,
        P2.ParentId,
        Level + 1
    FROM 
        Posts P2
    INNER JOIN 
        RecursivePostHierarchy RPH ON P2.ParentId = RPH.PostId
),
UserVotes AS (
    SELECT 
        V.UserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes V
    GROUP BY 
        V.UserId
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    RPH.Title AS QuestionTitle,
    RPH.CreationDate AS QuestionDate,
    UVotes.UpVotes,
    UVotes.DownVotes,
    V.TotalVotes,
    TS.TagName,
    TS.PostCount,
    TS.TotalViews
FROM 
    Users U
JOIN 
    RecursivePostHierarchy RPH ON RPH.OwnerUserId = U.Id
LEFT JOIN 
    UserVotes UVotes ON U.Id = UVotes.UserId
LEFT JOIN 
    (SELECT 
         V.UserId,
         COUNT(V.Id) AS TotalVotes
     FROM 
         Votes V
     WHERE 
         V.CreationDate > TIMESTAMP '2023-01-01'
     GROUP BY 
         V.UserId) AS V ON U.Id = V.UserId
LEFT JOIN 
    PostLinks PL ON RPH.PostId = PL.PostId
LEFT JOIN 
    TagStats TS ON TS.TagName IN (SELECT unnest(string_to_array(RPH.Title, ' ')))
WHERE 
    RPH.Level = 1
    AND U.Reputation > 100
    AND (UVotes.UpVotes - UVotes.DownVotes) > 10
ORDER BY 
    RPH.CreationDate DESC
LIMIT 100;
