WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
ClosedPostStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ClosureCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closed or Reopened
    GROUP BY 
        ph.PostId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.UpVotes,
    u.DownVotes,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.CommentCount,
    COALESCE(cp.ClosureCount, 0) AS ClosureCount,
    COALESCE(cp.LastClosedDate, 'No Closure') AS LastClosedDate,
    u.ReputationRank
FROM 
    TopUsers u
JOIN 
    Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN 
    ClosedPostStats cp ON p.Id = cp.PostId
WHERE 
    u.ReputationRank <= 10
ORDER BY 
    u.Reputation DESC, 
    p.CreationDate DESC;
