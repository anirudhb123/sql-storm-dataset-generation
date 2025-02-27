WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
),
RankedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS Rank,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(v.PostVoteCount, 0) AS TotalVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = p.Id) AS LinkCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS PostVoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id -- Assuming the CloseReasonId is stored in Comment
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    pu.Id AS UserId,
    pu.DisplayName,
    pu.Rank,
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.AnswerCount,
    pp.TotalVotes,
    pp.CommentCount,
    pp.LinkCount,
    rph.CreationDate AS LastEditDate,
    rph.Comment AS LastEditComment,
    Closed.CloseReasons
FROM 
    RankedUsers pu
JOIN 
    Posts pp ON pp.OwnerUserId = pu.Id
LEFT JOIN 
    RecursivePostHistory rph ON rph.PostId = pp.Id AND rph.rn = 1 -- Get the last edit
LEFT JOIN 
    ClosedPosts Closed ON Closed.PostId = pp.Id
WHERE 
    pu.Rank <= 100 -- Consider top 100 users
    AND pp.ViewCount > 100 -- Posts with more than 100 views
ORDER BY 
    pu.Rank, pp.ViewCount DESC;
