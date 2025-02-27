WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotesGiven,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotesGiven
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
HighReputationUsers AS (
    SELECT 
        UserId,
        Reputation,
        UpVotesGiven,
        DownVotesGiven
    FROM 
        UserReputation
    WHERE 
        Reputation > 1000 -- Only users with high reputation
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS CloseReasonCount,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON p.Id = ph.PostId
    INNER JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id 
    WHERE 
        ph.PostHistoryTypeId = 10 -- Posts that have been closed
    GROUP BY 
        p.Id
)
SELECT 
    up.UserId,
    up.Reputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.ViewCount,
    COALESCE(pwc.CommentCount, 0) AS CommentCount,
    COALESCE(cp.CloseReasonCount, 0) AS CloseReasonCount,
    COALESCE(cp.CloseReasons, 'No close reasons') AS CloseReasons
FROM 
    HighReputationUsers up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    PostsWithComments pwc ON rp.PostId = pwc.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.rn = 1 -- Getting only the most recent question for each user
ORDER BY 
    up.Reputation DESC, rp.CreationDate DESC;
