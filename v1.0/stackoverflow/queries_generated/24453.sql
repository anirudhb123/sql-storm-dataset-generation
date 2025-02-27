WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreatedAt >= (CURRENT_DATE - INTERVAL '1 year')
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(SUM(b.Class), 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(cr.Name, ', ') AS CloseReasonLists
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(c.CloseCount, 0) AS CloseCount,
        COALESCE(ua.VoteCount, 0) AS VoteCount,
        ua.UpVotes,
        ua.DownVotes,
        p.ViewCount,
        p.AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        CloseReasons c ON p.Id = c.PostId
    LEFT JOIN 
        UserActivity ua ON p.OwnerUserId = ua.UserId
)
SELECT 
    ps.PostId,
    ps.Title,
    p.OwnerDisplayName,
    ps.CloseCount,
    CASE 
        WHEN ps.VoteCount > 10 THEN 'Highly Active'
        WHEN ps.VoteCount BETWEEN 5 AND 10 THEN 'Moderately Active'
        ELSE 'Low Activity' 
    END AS ActivityLevel,
    COALESCE(CAST(ps.CloseCount AS VARCHAR), 'No closes') AS Closes,
    ROW_NUMBER() OVER (ORDER BY ps.ViewCount DESC) AS PopularityRank,
    RANK() OVER (ORDER BY ps.AnswerCount DESC) AS AnswerRank
FROM 
    PostSummary ps
JOIN 
    Users u ON ps.OwnerUserId = u.Id
WHERE 
    ps.CloseCount IS NULL OR ps.CloseCount >= 1
ORDER BY 
    ps.ViewCount DESC, ps.AnswerCount DESC
LIMIT 50;

