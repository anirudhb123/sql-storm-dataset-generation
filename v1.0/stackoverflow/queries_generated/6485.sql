WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.UpVotes) AS TotalUpVotes,
        SUM(rp.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    JOIN 
        Posts p ON p.Id = rp.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalPosts,
    up.TotalViews,
    up.TotalComments,
    up.TotalUpVotes,
    up.TotalDownVotes,
    RANK() OVER (ORDER BY up.TotalViews DESC) AS ViewRank
FROM 
    UserPerformance up
WHERE 
    up.TotalPosts > 0
ORDER BY 
    ViewRank, up.TotalViews DESC;
