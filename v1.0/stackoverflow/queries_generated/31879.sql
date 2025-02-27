WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.CreationDate,
        P.OwnerUserId,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        P.Id,
        P.Title,
        P.PostTypeId,
        P.CreationDate,
        P.OwnerUserId,
        RPH.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy RPH ON P.ParentId = RPH.PostId
),
PostScores AS (
    SELECT 
        P.Id,
        P.Title,
        P.ViewCount,
        P.Score,
        COALESCE(PH.UserDisplayName, 'Community User') AS LastEditor,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.LastEditDate DESC) AS LastEditRank
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT 
            PostId, 
            UserDisplayName, 
            MAX(LastEditDate) AS LastEditDate
         FROM 
            Posts
         GROUP BY PostId, UserDisplayName) PH ON P.Id = PH.PostId
),
PostActivity AS (
    SELECT 
        A.PostId,
        COUNT(A.Id) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts A
    LEFT JOIN 
        Votes V ON A.Id = V.PostId
    WHERE 
        A.PostTypeId = 2 -- Only Answers
    GROUP BY 
        A.PostId
),
PostResults AS (
    SELECT 
        RPH.PostId,
        RPH.Title,
        RPH.CreationDate,
        P.ViewCount,
        PS.Score,
        PA.AnswerCount,
        PA.UpVoteCount,
        PA.DownVoteCount,
        RPH.Level,
        P.OwnerDisplayName
    FROM 
        RecursivePostHierarchy RPH
    JOIN 
        Posts P ON RPH.PostId = P.Id
    JOIN 
        PostScores PS ON P.Id = PS.Id
    JOIN 
        PostActivity PA ON P.Id = PA.PostId
)

SELECT 
    PR.Title,
    PR.CreationDate,
    PR.ViewCount,
    PR.Score,
    PR.AnswerCount,
    PR.UpVoteCount,
    PR.DownVoteCount,
    CASE 
        WHEN PR.Level = 0 THEN 'Root Question'
        ELSE CONCAT('Response Level: ', PR.Level)
    END AS ResponseLevel,
    CASE 
        WHEN PR.OwnerDisplayName IS NULL THEN 'Anonymous'
        ELSE PR.OwnerDisplayName
    END AS Owner
FROM 
    PostResults PR
WHERE 
    PR.Score > 0
ORDER BY 
    PR.Score DESC, PR.CreationDate ASC
OFFSET 0 ROWS
FETCH NEXT 100 ROWS ONLY;
