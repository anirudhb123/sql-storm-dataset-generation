WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE((SELECT MAX(Score) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS Upvotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByType
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PopularTags AS (
    SELECT 
        t.TagName,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        TotalViews DESC
    LIMIT 5
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(u.UpVotes) AS TotalUpvotes,
        SUM(u.DownVotes) AS TotalDownvotes,
        AVG(COALESCE(NULLIF(p.Score, 0), NULL)) AS AveragePostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.Upvotes,
    ut.UserId,
    ut.DisplayName,
    ut.PostCount,
    ut.TotalUpvotes,
    ut.TotalDownvotes,
    ut.AveragePostScore,
    pt.TagName,
    pt.TotalViews
FROM 
    RankedPosts rp
JOIN 
    UserStatistics ut ON rp.PostId = (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ut.UserId ORDER BY p.CreationDate DESC LIMIT 1)
LEFT JOIN 
    PopularTags pt ON rp.Title LIKE '%' || pt.TagName || '%'
WHERE 
    rp.RankByType <= 10
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
