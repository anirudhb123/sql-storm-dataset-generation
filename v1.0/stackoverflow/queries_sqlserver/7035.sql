
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
),
UserActivities AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '2 years'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ua.DisplayName,
    ua.BadgeCount,
    ua.TotalBounties,
    ua.UpVotes,
    ua.DownVotes,
    COUNT(DISTINCT rp.PostId) AS PostsCreated,
    SUM(rp.Score) AS TotalScore,
    SUM(rp.ViewCount) AS TotalViews
FROM 
    UserActivities ua
JOIN 
    RankedPosts rp ON ua.UserId = rp.OwnerUserId
GROUP BY 
    ua.DisplayName, ua.BadgeCount, ua.TotalBounties, ua.UpVotes, ua.DownVotes
ORDER BY 
    TotalScore DESC, TotalViews DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
