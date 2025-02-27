WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
), 
PostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT rp.PostId) AS QuestionCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        SUM(CASE WHEN rp.RN = 1 THEN 1 ELSE 0 END) AS MostRecentQuestionsCount
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId AND v.UserId = u.Id
    GROUP BY 
        u.Id
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
RecentActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS PostHistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.CreationDate > DATEADD(DAY, -30, GETDATE())
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ps.UserId,
    ps.DisplayName,
    ps.QuestionCount,
    ps.UpVotes,
    ps.DownVotes,
    ub.BadgeCount,
    ra.CommentCount,
    ra.PostHistoryCount,
    (ps.UpVotes - ps.DownVotes) AS VoteBalance,
    DENSE_RANK() OVER (ORDER BY (ps.UpVotes - ps.DownVotes) DESC) AS VoteRank
FROM 
    PostStats ps
LEFT JOIN 
    UserBadges ub ON ps.UserId = ub.UserId
LEFT JOIN 
    RecentActivity ra ON ps.UserId = ra.OwnerUserId
WHERE 
    ps.QuestionCount > 0
ORDER BY 
    VoteBalance DESC, ps.QuestionCount DESC;

This SQL query aims to extract various statistics related to users based on their questions on a Stack Overflow-like platform. It features:
- Common Table Expressions (CTEs) to calculate the number of questions and their statistics, upvotes, downvotes, and recent activity.
- Window functions to rank users by their vote balance (the difference between upvotes and downvotes).
- Joins between users, their posts, votes, and badges to provide a comprehensive view of user engagement and activity.
- A filter to ensure only users with questions are included in the final result.

