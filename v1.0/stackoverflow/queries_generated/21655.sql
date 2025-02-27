WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.Score IS NOT NULL 
        AND p.CreationDate > (NOW() - INTERVAL '1 year')
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        string_agg(cr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Post Closed and Post Reopened
    GROUP BY 
        ph.PostId
),
MostCommentedPosts AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
    HAVING 
        COUNT(*) > 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.UpVotes,
    rp.DownVotes,
    COALESCE(cr.CloseReasonNames, 'No close reasons') AS CloseReasons,
    COALESCE(mcp.TotalComments, 0) AS CommentCount,
    CASE 
        WHEN rp.Rank = 1 THEN 'Most Recent'
        ELSE NULL 
    END AS IsTopPost
FROM 
    RankedPosts rp
LEFT JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
LEFT JOIN 
    MostCommentedPosts mcp ON rp.PostId = mcp.PostId
WHERE 
    rp.UpVotes + 3 * rp.DownVotes > 10 -- Bizarre scoring logic
ORDER BY 
    rp.Score DESC, rp.UpVotes DESC;

-- Additional CTE for finding Users with the most Badges 
WITH UserBadgeCount AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
    HAVING 
        COUNT(*) > 2
)
SELECT 
    u.DisplayName,
    ub.BadgeCount,
    CASE 
        WHEN ub.BadgeCount > 5 THEN 'Master Badge Holder'
        ELSE 'Novice Badge Holder'
    END AS BadgeHolderStatus
FROM 
    Users u
JOIN 
    UserBadgeCount ub ON u.Id = ub.UserId
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users) 
ORDER BY 
    ub.BadgeCount DESC;

This SQL query encompasses several complex constructs including Common Table Expressions (CTEs), outer joins, ranking functions, and conditional logic for scoring and categorization. It retrieves ranked posts with voting metrics while handling close reasons and identifying popular comments. Additionally, it calculates user badge counts with an evaluation of their status based on badge ownership, illustrating the capabilities of SQL in manipulation and aggregation of data.
