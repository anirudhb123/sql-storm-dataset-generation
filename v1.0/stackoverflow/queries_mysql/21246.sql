
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(DISTINCT p.Id) AS PostCount,
        MAX(u.LastAccessDate) AS LastActiveDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        @row_number := IF(@prev_post_type = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type := p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id,
        (SELECT @row_number := 0, @prev_post_type := '') AS vars
    WHERE 
        p.CreationDate >= (NOW() - INTERVAL 1 YEAR)
    GROUP BY 
        p.Id, p.Title
),
RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        b.Date AS BadgeDate,
        DENSE_RANK() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Badges b
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.UpVoteCount,
    u.DownVoteCount,
    u.PostCount,
    tp.PostId,
    tp.Title,
    tp.CommentCount,
    tp.TotalUpVotes,
    tp.TotalDownVotes,
    COALESCE(rb.BadgeName, 'No Badge') AS BadgeName
FROM 
    UserStats u
LEFT JOIN 
    TopPostStats tp ON u.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN 
    RecentBadges rb ON u.UserId = rb.UserId AND rb.BadgeRank = 1
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    u.UpVoteCount DESC,
    u.DownVoteCount ASC;
