WITH RecursiveBadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount, MIN(Date) AS FirstBadgeDate
    FROM Badges
    GROUP BY UserId
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        (SELECT COUNT(DISTINCT pl.RelatedPostId)
         FROM PostLinks pl 
         WHERE pl.PostId = p.Id) AS RelatedPostCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    LEFT JOIN RecursiveBadgeCounts bc ON u.Id = bc.UserId
),
UserPosts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(pe.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(pe.DownVotes, 0)) AS TotalDownVotes,
        SUM(COALESCE(pe.CommentCount, 0)) AS TotalComments
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostEngagement pe ON p.Id = pe.PostId
    GROUP BY u.Id
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ur.BadgeCount,
    up.TotalPosts,
    up.TotalUpVotes,
    up.TotalDownVotes,
    up.TotalComments,
    ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC, ur.BadgeCount DESC) AS OverallRank,
    CASE 
        WHEN ur.Reputation IS NULL THEN 'Reputation data not available'
        ELSE 'Active User'
    END AS UserStatus,
    COALESCE(
        (SELECT STRING_AGG(CASE WHEN Tags.TagName IS NULL THEN 'Unknown Tag' ELSE Tags.TagName END, ', ') 
         FROM UNNEST(STRING_TO_ARRAY(PTS.Tags, ',')) AS Tags(TagName)
         WHERE Tags.TagName IS NOT NULL), 
        'No Tags') AS UserTags
FROM UserReputation ur
LEFT JOIN UserPosts up ON ur.UserId = up.UserId
ORDER BY ur.Reputation DESC, ur.BadgeCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
