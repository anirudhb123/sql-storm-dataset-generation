WITH RECURSIVE UsersWithBadges AS (
    SELECT u.Id, u.DisplayName, u.Reputation, b.Name AS BadgeName, b.Date AS BadgeDate
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000
    
    UNION ALL
    
    SELECT u.Id, u.DisplayName, u.Reputation, b.Name AS BadgeName, b.Date AS BadgeDate
    FROM Users u
    JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation <= 1000 AND b.Class = 1
),
PostVoteCounts AS (
    SELECT p.Id AS PostId,
           COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
           COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id
),
PostsWithTags AS (
    SELECT p.Id AS PostId, 
           STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN LATERAL (
        SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName
    ) t ON true
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, ph.UserDisplayName AS ClosedBy
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10
),
NegativeReputationUsers AS (
    SELECT DISTINCT u.Id, u.DisplayName
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation < 0
)

SELECT u.DisplayName,
       COUNT(DISTINCT b.Id) AS BadgeCount,
       SUM(CASE WHEN uc.Id IS NOT NULL THEN 1 ELSE 0 END) AS UsersWithNegativeReputation,
       COALESCE(SUM(pvc.UpVotes) - SUM(pvc.DownVotes), 0) AS NetVotes,
       LISTAGG(DISTINCT pwt.Tags, '; ') AS PostTags,
       SUM(CASE WHEN cp.ClosedBy IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPostCount
FROM Users u
LEFT JOIN Badges b ON u.Id = b.UserId
LEFT JOIN UsersWithBadges uwb ON u.Id = uwb.Id
LEFT JOIN PostVoteCounts pvc ON pvc.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
LEFT JOIN PostsWithTags pwt ON pwt.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
LEFT JOIN ClosedPosts cp ON cp.Id IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
LEFT JOIN NegativeReputationUsers uc ON u.Id = uc.Id
WHERE u.Reputation >= 0
GROUP BY u.DisplayName
HAVING COUNT(DISTINCT b.Id) > 0
ORDER BY BadgeCount DESC, SUM(pvc.UpVotes) DESC;
