WITH UserBadgeCount AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.PostTypeId, 
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(SUM(v.VoteTypeId = 10), 0) AS DeletionVotes,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(SUM(v.VoteTypeId = 2), 0) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.CreationDate
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate, 
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate
),
UserWithPosts AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COALESCE(ubc.BadgeCount, 0) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeCount ubc ON u.Id = ubc.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    uwp.UserId,
    uwp.DisplayName,
    uwp.Reputation,
    uwp.BadgeCount,
    p.PostId,
    p.Title,
    p.UpVotes,
    p.DownVotes,
    COALESCE(cpd.CloseCount, 0) AS CloseCount,
    cpd.CloseReasons,
    p.Rank,
    CASE 
        WHEN p.DeletionVotes > 0 THEN 'Potentially Deleted'
        WHEN cpd.CloseCount > 0 THEN 'Closed with reasons: ' || cpd.CloseReasons
        ELSE 'Active'
    END AS PostStatus
FROM 
    UserWithPosts uwp
JOIN 
    PostStatistics p ON uwp.TotalPosts > 0
LEFT JOIN 
    ClosedPostDetails cpd ON p.PostId = cpd.PostId
WHERE 
    uwp.BadgeCount > 0 AND 
    (p.UpVotes - p.DownVotes) > 10
ORDER BY 
    uwp.Reputation DESC, p.Rank
LIMIT 100;

This query performs a rather intricate operation that combines multiple Common Table Expressions (CTEs) to achieve a comprehensive summary of user contributions, badge counts, and post statistics over the past year, while handling various conditions like counting closed posts and votes, providing a filtered yet insightful view into the activity within the Stack Overflow schema.
