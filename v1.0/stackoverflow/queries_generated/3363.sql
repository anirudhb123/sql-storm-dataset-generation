WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpvoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownvoteCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(crt.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.CloseCount,
    ps.ReopenCount,
    COALESCE(pr.CloseReasons, '{}') AS CloseReasons,
    ur.DisplayName AS TopUserDisplayName,
    ur.Reputation AS TopUserReputation,
    ur.Rank as UserRank
FROM 
    PostStats ps
LEFT JOIN 
    PostCloseReasons pr ON ps.PostId = pr.PostId
JOIN 
    UserReputation ur ON ur.UserId = (
        SELECT 
            OwnerUserId 
        FROM 
            Posts 
        WHERE 
            Id = ps.PostId
    )
ORDER BY 
    ps.Score DESC, ps.CreationDate ASC
LIMIT 100;
