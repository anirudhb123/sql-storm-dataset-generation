WITH UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(p.ClosedDate, 'No Closure') AS Closure_Date,
        u.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1
            ELSE 0 
        END AS IsAcceptedAnswer
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1
),
TopPosts AS (
    SELECT
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.AnswerCount,
        pd.Closure_Date,
        pd.OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY pd.OwnerDisplayName ORDER BY pd.ViewCount DESC) AS PostRank
    FROM PostDetails pd
),
PostsWithComments AS (
    SELECT
        tp.PostId,
        COUNT(c.Id) AS CommentCount
    FROM TopPosts tp
    LEFT JOIN Comments c ON tp.PostId = c.PostId
    GROUP BY tp.PostId
),
FinalResults AS (
    SELECT 
        tr.DisplayName AS Owner,
        tp.Title,
        tp.ViewCount,
        tp.AnswerCount,
        tp.Closure_Date,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        ur.Reputation,
        ur.ReputationRank
    FROM TopPosts tp
    LEFT JOIN PostsWithComments pc ON tp.PostId = pc.PostId
    JOIN UserReputation ur ON tp.OwnerDisplayName = ur.DisplayName
    WHERE ur.Reputation > 1000
    ORDER BY ur.Reputation DESC, tp.ViewCount DESC
)
SELECT 
    Owner,
    Title,
    ViewCount,
    AnswerCount,
    Closure_Date,
    CommentCount,
    Reputation,
    ReputationRank
FROM FinalResults
WHERE ReputationRank <= 10
UNION ALL
SELECT 
    'Others' AS Owner,
    'Aggregate Data' AS Title,
    SUM(ViewCount) AS ViewCount,
    SUM(AnswerCount) AS AnswerCount,
    NULL AS Closure_Date,
    SUM(CommentCount) AS CommentCount,
    NULL AS Reputation,
    NULL AS ReputationRank
FROM FinalResults
HAVING COUNT(*) > 0
ORDER BY Reputation DESC NULLS LAST, ViewCount DESC;
