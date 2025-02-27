WITH
  RankedPosts AS (
    SELECT
      p.Id AS PostId,
      p.Title,
      p.Score,
      p.ViewCount,
      p.CreationDate,
      ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM
      Posts p
    WHERE
      p.PostTypeId = 1
  ),
  
  UserBadges AS (
    SELECT
      u.Id AS UserId,
      COUNT(b.Id) AS BadgeCount
    FROM
      Users u
      LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY
      u.Id
  ),
  
  PostVoteSummary AS (
    SELECT
      postId,
      COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
      COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes,
      COUNT(v.Id) AS TotalVotes
    FROM
      Votes v
      JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY
      postId
  ),
  
  LatestActivity AS (
    SELECT
      p.Id AS PostId,
      MAX(COALESCE(p.LastActivityDate, p.CreationDate)) AS LastActivity
    FROM
      Posts p
    GROUP BY
      p.Id
  )
  
SELECT
  up.DisplayName AS UserDisplayName,
  rp.Title,
  rp.Score,
  rp.ViewCount,
  ub.BadgeCount,
  pvs.UpVotes,
  pvs.DownVotes,
  la.LastActivity
FROM
  RankedPosts rp
  JOIN Users up ON rp.OwnerUserId = up.Id
  LEFT JOIN UserBadges ub ON up.Id = ub.UserId
  LEFT JOIN PostVoteSummary pvs ON rp.PostId = pvs.postId
  LEFT JOIN LatestActivity la ON rp.PostId = la.PostId
WHERE
  rp.UserPostRank <= 5
  AND (ub.BadgeCount IS NULL OR ub.BadgeCount > 0)
ORDER BY
  rp.ViewCount DESC,
  rp.Score DESC;
This SQL query fetches the top posts of users who have earned badges, summarizing their upvotes and ensuring it considers recent activity, using various SQL features such as CTEs, window functions, and outer joins.
