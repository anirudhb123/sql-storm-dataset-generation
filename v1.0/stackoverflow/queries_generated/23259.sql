WITH RankedUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostOrder
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(*) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedReasonCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or reopened posts
    GROUP BY 
        ph.PostId, ph.CreationDate
),
AnswerDetails AS (
    SELECT 
        p.Id AS QuestionId,
        COUNT(a.Id) AS AnswerCount,
        SUM(COALESCE(a.Score, 0)) AS TotalAnswerScore,
        COALESCE(MAX(a.CreationDate), '1970-01-01') AS LastAnswerDate
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 -- Answers linked to Questions
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    r.ReputationRank,
    tp.Title,
    tp.CreationDate AS PostCreationDate,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    cp.CloseCount,
    cp.ClosedReasonCount,
    ad.AnswerCount,
    ad.TotalAnswerScore,
    ad.LastAnswerDate
FROM 
    RankedUsers u
JOIN 
    TopPosts tp ON u.Id = tp.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON tp.PostId = cp.PostId
LEFT JOIN 
    AnswerDetails ad ON tp.PostId = ad.QuestionId
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users) -- Above average reputation
    AND (tp.CommentCount > 5 OR tp.UpVotes > 10) -- Posts with significant interaction
ORDER BY 
    r.ReputationRank, tp.CreationDate DESC
LIMIT 100;
