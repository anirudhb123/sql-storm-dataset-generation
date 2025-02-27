
WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.AccountId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(b.Id) AS BadgeCount,
        (@row_number:=IF(@prev_account = u.AccountId, @row_number + 1, 1)) AS Rank,
        @prev_account := u.AccountId
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    CROSS JOIN (SELECT @row_number := 0, @prev_account := NULL) AS init
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.AccountId
),
PostSummary AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        MAX(b.Class) AS HighestBadge
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId
),
PostLinkStats AS (
    SELECT
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount,
        GROUP_CONCAT(rpt.TagName SEPARATOR ', ') AS RelatedPostTags
    FROM PostLinks pl
    LEFT JOIN Posts rp ON pl.RelatedPostId = rp.Id
    LEFT JOIN Tags rpt ON rp.Tags LIKE CONCAT('%', rpt.TagName, '%') 
    GROUP BY pl.PostId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.UpVotes AS TotalUpVotes,
    us.DownVotes AS TotalDownVotes,
    ps.PostId,
    ps.Title,
    ps.Body,
    ps.CommentCount,
    ps.UpVotes AS PostUpVotes,
    ps.DownVotes AS PostDownVotes,
    pls.RelatedPostCount,
    pls.RelatedPostTags,
    (CASE 
        WHEN us.Rank = 1 THEN 'Top User'
        WHEN us.Reputation > 1000 THEN 'Active User'
        ELSE 'New User' 
    END) AS UserType
FROM UserStats us
JOIN PostSummary ps ON us.UserId = ps.OwnerUserId
LEFT JOIN PostLinkStats pls ON ps.PostId = pls.PostId
WHERE us.Reputation >= 500 
  AND (ps.CommentCount > 0 OR ps.UpVotes > 0)
  AND (ps.Body IS NOT NULL OR ps.Title IS NOT NULL) 
ORDER BY us.Reputation DESC, ps.CommentCount DESC, ps.UpVotes DESC;
