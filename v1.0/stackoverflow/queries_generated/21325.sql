WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Close and Reopen
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    us.UserId,
    us.Reputation,
    us.CommentCount,
    us.TotalBounties,
    cpr.CloseCount,
    cpr.CloseReasons
FROM 
    RankedPosts rp
JOIN 
    Users u ON u.Id = rp.OwnerUserId
JOIN 
    UserStatistics us ON u.Id = us.UserId
LEFT JOIN 
    ClosedPostReasons cpr ON rp.PostId = cpr.PostId
WHERE 
    rp.PostRank = 1
    AND (us.Reputation > 100 OR us.TotalBounties > 0)
    AND rp.AnswerCount > 0
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 10;

WITH PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVoteCount,
        COALESCE(ROUND(AVG(CASE WHEN ph.PostHistoryTypeId = 5 THEN 1 ELSE 0 END) FILTER (WHERE ph.PostId = p.Id)::numeric, 2), 0) AS AvgBodyEdits
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    pa.PostId,
    pa.UpVoteCount,
    pa.DownVoteCount,
    (pa.UpVoteCount - pa.DownVoteCount) AS NetVotes,
    pa.AvgBodyEdits,
    CASE 
        WHEN pa.AvgBodyEdits > 2 THEN 'Highly Edited'
        WHEN pa.AvgBodyEdits BETWEEN 1 AND 2 THEN 'Moderately Edited'
        ELSE 'Seldom Edited'
    END AS EditFrequency
FROM 
    PostAnalytics pa
WHERE 
    pa.UpVoteCount IS NOT NULL
ORDER BY 
    NetVotes DESC
LIMIT 5;

SELECT 
    p.Title AS PostTitle,
    STRING_AGG(DISTINCT CONCAT(c.UserDisplayName, ': ', c.Text), ' | ') AS TopComments
FROM 
    Posts p
JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.ViewCount IS NOT NULL
GROUP BY 
    p.Id
ORDER BY 
    SUM(c.Score) DESC
LIMIT 3;

WITH AllUserVotes AS (
    SELECT
        u.Id AS UserId,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)
SELECT 
    UserId,
    TotalVotes,
    UpVotes,
    DownVotes,
    (TotalVotes - DownVotes) AS VoteBalance,
    CASE 
        WHEN VoteBalance >= 50 THEN 'Positive Influencer'
        WHEN VoteBalance < 0 THEN 'Negative Influ
