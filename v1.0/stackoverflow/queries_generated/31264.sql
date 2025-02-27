WITH RecursiveCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        UpVotes = COALESCE(SUM(V.VoteTypeId = 2), 0),
        DownVotes = COALESCE(SUM(V.VoteTypeId = 3), 0),
        AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    WHERE 
        P.PostTypeId = 1 -- Only questions
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, AcceptedAnswerId

    UNION ALL

    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        UpVotes = COALESCE(SUM(V.VoteTypeId = 2), 0),
        DownVotes = COALESCE(SUM(V.VoteTypeId = 3), 0),
        AcceptedAnswerId,
        Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursiveCTE R ON P.ParentId = R.PostId
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, AcceptedAnswerId
),

RankedPosts AS (
    SELECT 
        P.PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.UpVotes,
        P.DownVotes,
        RANK() OVER (ORDER BY P.Score DESC, P.ViewCount DESC) AS PostRank
    FROM 
        RecursiveCTE P
)

SELECT 
    U.DisplayName AS UserName,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.UpVotes,
    RP.DownVotes,
    CASE 
        WHEN RP.AcceptedAnswerId IS NOT NULL THEN 'Answered'
        ELSE 'Unanswered'
    END AS AnswerStatus,
    COUNT(C.Id) AS CommentCount,
    MAX(B.Name) AS HighestBadge
FROM 
    RankedPosts RP
JOIN 
    Users U ON U.Id = RP.AcceptedAnswerId
LEFT JOIN 
    Comments C ON C.PostId = RP.PostId
LEFT JOIN 
    Badges B ON B.UserId = U.Id AND B.Class = 1 -- Take only Gold Badges
WHERE 
    RP.PostRank <= 10 -- Top 10 posts
GROUP BY 
    U.DisplayName, RP.Title, RP.Score, RP.ViewCount, RP.UpVotes, RP.DownVotes, RP.AcceptedAnswerId
ORDER BY 
    RP.Score DESC;
