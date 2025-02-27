-- Performance benchmarking query to analyze post activity, user engagement and editing history
WITH PostActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(SUM(b.Id), 0) AS BadgeCount,
        COALESCE(MAX(ph.CreationDate), p.CreationDate) AS LastEditDate
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Badges b ON b.UserId = p.OwnerUserId
    LEFT JOIN
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(pa.ViewCount), 0) AS TotalViews,
        COUNT(DISTINCT pa.PostId) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM
        Users u
    LEFT JOIN
        Posts pa ON u.Id = pa.OwnerUserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
)
SELECT
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.CommentCount,
    pa.UpVotes,
    pa.DownVotes,
    pa.LastEditDate,
    ue.UserId,
    ue.DisplayName,
    ue.Reputation,
    ue.TotalViews AS UserTotalViews,
    ue.TotalPosts,
    ue.TotalBadges
FROM
    PostActivity pa
JOIN
    Users u ON pa.Id = u.Id
JOIN
    UserEngagement ue ON u.Id = ue.UserId
ORDER BY
    pa.ViewCount DESC;
