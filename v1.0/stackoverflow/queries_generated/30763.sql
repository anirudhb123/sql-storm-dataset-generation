WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
), 
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseVotes,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS ReopenVotes,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END), 0) AS DeleteVotes,
        COUNT(DISTINCT pp.PostId) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts pp ON u.Id = pp.OwnerUserId AND pp.PostTypeId = 1
    LEFT JOIN 
        PostHistory ph ON pp.Id = ph.PostId
    GROUP BY 
        u.Id
), 
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        CloseVotes,
        ReopenVotes,
        DeleteVotes,
        ROW_NUMBER() OVER (ORDER BY QuestionCount DESC) AS Rank
    FROM 
        UserPostStats
    WHERE 
        QuestionCount > 0
)

SELECT 
    au.DisplayName,
    au.QuestionCount,
    au.CloseVotes,
    au.ReopenVotes,
    au.DeleteVotes,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount
FROM 
    ActiveUsers au
JOIN 
    RankedPosts rp ON au.UserId = rp.OwnerUserId
WHERE 
    au.Rank <= 10
ORDER BY 
    au.QuestionCount DESC, 
    rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;

-- Explanation of the query:
-- 1. RankedPosts: Retrieves all questions, ranks them by CreationDate for each owner.
-- 2. UserPostStats: Aggregates data for each user regarding their posts, including counts of closure,
--    reopening, and deletion votes along with total question count.
-- 3. ActiveUsers: Selects users who have posted questions and ranks them by question counts,
--    only including users who have at least one question.
-- 4. The final select combines the user statistics from ActiveUsers with their latest ranked posts,
--    filtering to show only the top 10 users by question count and limiting the displayed results to 5.
