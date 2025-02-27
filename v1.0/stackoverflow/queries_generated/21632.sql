WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        AVG(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            WHEN v.VoteTypeId = 3 THEN -1 
            ELSE 0 
        END) AS AverageVoteScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
QuestionDetails AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.ViewCount,
        pm.CommentCount,
        pm.TotalBounty,
        pm.AverageVoteScore,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId
    FROM 
        Posts p
    JOIN 
        PostMetrics pm ON p.Id = pm.PostId
    WHERE 
        p.PostTypeId = 1
),
AcceptedAnswerDetails AS (
    SELECT 
        q.QuestionId,
        a.Id AS AnswerId,
        a.OwnerUserId,
        u.DisplayName AS AnswerOwnerName,
        a.CreationDate AS AnswerCreationDate
    FROM 
        QuestionDetails q
    LEFT JOIN 
        Posts a ON q.AcceptedAnswerId = a.Id
    LEFT JOIN 
        Users u ON a.OwnerUserId = u.Id
)
SELECT 
    q.Title AS QuestionTitle,
    q.ViewCount,
    q.CommentCount,
    q.TotalBounty,
    q.AverageVoteScore,
    a.AnswerId,
    a.AnswerOwnerName,
    q.QuestionId,
    q.AcceptedAnswerId,
    CASE 
        WHEN a.AnswerId IS NOT NULL THEN 'Accepted' 
        ELSE 'Not Accepted' 
    END AS AcceptanceStatus,
    STRING_AGG(CASE WHEN bh.PostHistoryTypeId = 18 THEN 'Merged' END, ', ') AS MergeStatus
FROM 
    QuestionDetails q
LEFT JOIN 
    AcceptedAnswerDetails a ON q.QuestionId = a.QuestionId
LEFT JOIN 
    PostHistory bh ON q.QuestionId = bh.PostId 
        AND (bh.PostHistoryTypeId = 18 OR bh.PostHistoryTypeId = 10 OR bh.PostHistoryTypeId = 11)
GROUP BY 
    q.QuestionId, q.Title, q.ViewCount, q.CommentCount, q.TotalBounty, 
    q.AverageVoteScore, a.AnswerId, a.AnswerOwnerName
ORDER BY 
    q.ViewCount DESC NULLS LAST, 
    q.CommentCount DESC, 
    q.TotalBounty DESC;
