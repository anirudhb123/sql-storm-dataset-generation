
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.TotalBounty,
    ua.UpVotes,
    ua.DownVotes,
    ua.BadgeCount,
    ua.TotalViews,
    @view_rank := @view_rank + 1 AS ViewRank,
    @post_rank := @post_rank + 1 AS PostRank
FROM 
    UserActivity ua
JOIN (SELECT @view_rank := 0, @post_rank := 0) r 
ORDER BY 
    ua.TotalViews DESC, ua.PostCount DESC;
