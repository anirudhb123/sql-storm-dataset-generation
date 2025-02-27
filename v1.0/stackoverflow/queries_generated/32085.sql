WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
),

FilteredPosts AS (
    SELECT 
        rp.*,
        COALESCE(b.Name, 'No Badge') AS UserBadge,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Date = (
            SELECT MAX(Date) 
            FROM Badges 
            WHERE UserId = u.Id
        )
    WHERE 
        rp.PostRank <= 5 -- Top 5 posts per user
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id -- Assuming Comment holds CloseReasonId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
)

SELECT 
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.UserReputation,
    fp.UserBadge,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    cp.CloseReasons,
    ua.PostCount,
    ua.TotalUpVotes,
    ua.TotalDownVotes
FROM 
    FilteredPosts fp
LEFT JOIN 
    ClosedPosts cp ON fp.PostId = cp.PostId
LEFT JOIN 
    UserActivity ua ON fp.OwnerUserId = ua.UserId
ORDER BY 
    fp.Score DESC, UserReputation DESC;
