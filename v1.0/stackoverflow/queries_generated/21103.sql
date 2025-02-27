WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS Rank,
        LAG(P.CreationDate) OVER (PARTITION BY P.Id ORDER BY P.CreationDate) AS PreviousCreationDate
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount
),
ClosedPosts AS (
    SELECT 
        Hist.PostId,
        Hist.UserId,
        Hist.CreationDate AS ClosedDate,
        CR.Name AS CloseReason,
        Hist.Comment
    FROM 
        PostHistory Hist
    JOIN 
        CloseReasonTypes CR ON Hist.Comment::integer = CR.Id
    WHERE 
        Hist.PostHistoryTypeId = 10
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        CASE 
            WHEN U.Reputation > 1000 THEN 'High'
            WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM 
        Users U
),
TagDetails AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.Id, T.TagName
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.VoteCount,
    PS.UpVotes,
    PS.DownVotes,
    COALESCE(CP.ClosedDate, 'No Closure') AS ClosedStatus,
    COALESCE(CP.CloseReason, 'N/A') AS ClosureReason,
    UR.ReputationLevel,
    TD.TagName,
    TD.PostCount,
    CASE 
        WHEN PS.Rank = 1 THEN 'This Post is the most recent'
        ELSE 'Older Post'
    END AS PostRecencyStatus,
    EXTRACT(EPOCH FROM COALESCE(CP.ClosedDate, CURRENT_TIMESTAMP) - PS.PreviousCreationDate) AS SecondsSincePrevious
FROM 
    PostStats PS
LEFT JOIN 
    ClosedPosts CP ON PS.PostId = CP.PostId
JOIN 
    UserReputation UR ON PS.OwnerUserId = UR.UserId
JOIN 
    TagDetails TD ON TD.PostCount > 5
WHERE 
    PS.Score > 0 
    OR (PS.Score = 0 AND PS.ViewCount > 100)
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC
LIMIT 100;
