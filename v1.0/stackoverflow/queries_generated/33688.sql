WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Body,
        p.OwnerUserId,
        1 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting from Questions
    UNION ALL
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.Score,
        a.ViewCount,
        a.Body,
        a.OwnerUserId,
        r.Depth + 1
    FROM 
        Posts a
    JOIN 
        RecursiveCTE r ON a.ParentId = r.PostId
    WHERE 
        a.PostTypeId = 2  -- Looking for Answers
),
RankedPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        r.Depth,
        DENSE_RANK() OVER (PARTITION BY r.OwnerUserId ORDER BY r.Score DESC) AS ScoreRank
    FROM 
        RecursiveCTE r
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersGiven,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(ph.Id) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    ua.QuestionsAsked,
    ua.AnswersGiven,
    ua.DownVotesReceived,
    pp.Title,
    pp.CreationDate,
    pp.Depth,
    phs.FirstEditDate,
    phs.LastEditDate,
    phs.EditCount,
    phs.ClosedCount,
    CASE 
        WHEN pp.Depth = 1 THEN 'Original Question'
        ELSE 'Answer to Question'
    END AS PostType,
    pp.ViewCount
FROM 
    UserActivity ua
JOIN 
    RankedPosts pp ON ua.UserId = pp.OwnerUserId
JOIN 
    PostHistorySummary phs ON pp.PostId = phs.PostId
WHERE 
    pp.ScoreRank <= 5  -- Top 5 posts by score per user
ORDER BY 
    ua.DisplayName,
    pp.Score DESC;
