WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.AnswerCount,
        p.ViewCount,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Starting from Questions
     
    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.AnswerCount,
        p.ViewCount,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursiveCTE r ON p.ParentId = r.PostId -- Join to find related answers
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
)
SELECT
    r.PostId,
    r.Title,
    r.AnswerCount,
    r.ViewCount,
    CASE
        WHEN u.TotalPosts > 0 THEN (u.TotalUpVotes - u.TotalDownVotes) / u.TotalPosts
        ELSE 0
    END AS UserEngagementScore,
    COALESCE(ph.EditCount, 0) AS TotalEdits,
    ph.LastEditDate
FROM 
    RecursiveCTE r
LEFT JOIN 
    UserStats u ON r.OwnerUserId = u.UserId
LEFT JOIN 
    PostHistoryStats ph ON r.PostId = ph.PostId
WHERE 
    r.ViewCount > 100 AND 
    u.BadgeCount > 0 -- Filters for popular posts by users with badges
ORDER BY 
    r.ViewCount DESC, 
    u.TotalUpVotes DESC
LIMIT 10;
This SQL query demonstrates the use of recursive common table expressions (CTEs) to fetch questions and their corresponding answers, along with user statistics such as total upvotes and downvotes. It also incorporates post edit history to evaluate engagement, and presents the top posts based on view counts and user accolades.
