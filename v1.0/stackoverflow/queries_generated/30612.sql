WITH RecursivePostHierarchy AS (
    SELECT Id, Title, ParentId, OwnerUserId, CreationDate, Score, 1 AS Level
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT p.Id, p.Title, p.ParentId, p.OwnerUserId, p.CreationDate, p.Score, Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.Id
),
RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        CASE 
            WHEN p.Score > 0 THEN 'Positive'
            WHEN p.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreCategory,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PopularUsers AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.BadgeCount,
        COUNT(r.Id) AS PostCount
    FROM UserBadgeCounts ub
    INNER JOIN RankedPosts r ON ub.UserId = r.OwnerUserId
    WHERE ub.BadgeCount > 0
    GROUP BY ub.UserId, ub.DisplayName, ub.BadgeCount
    HAVING COUNT(r.Id) > 5
),
RecentVotes AS (
    SELECT 
        v.UserId,
        v.PostId,
        v.VoteTypeId,
        ROW_NUMBER() OVER (PARTITION BY v.UserId ORDER BY v.CreationDate DESC) AS RecentVoteRank
    FROM Votes v 
    WHERE v.CreationDate >= NOW() - INTERVAL '30 days'
),
VoteBreakdown AS (
    SELECT 
        ur.UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM RecentVotes v
    INNER JOIN Users ur ON v.UserId = ur.Id
    GROUP BY ur.UserId
)

SELECT 
    pu.DisplayName AS PopularUser,
    pu.BadgeCount,
    pu.PostCount,
    p.Title AS RecentPostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.Score AS PostScore,
    CASE 
        WHEN v.UpVotesCount > v.DownVotesCount THEN 'More Upvotes'
        WHEN v.UpVotesCount < v.DownVotesCount THEN 'More Downvotes'
        ELSE 'Equal Votes'
    END AS VoteBalance
FROM PopularUsers pu
JOIN RankedPosts rp ON pu.UserId = rp.OwnerUserId
LEFT JOIN VoteBreakdown v ON pu.UserId = v.UserId
WHERE rp.PostRank = 1
ORDER BY pu.BadgeCount DESC, pu.PostCount DESC, rp.CreationDate DESC;
