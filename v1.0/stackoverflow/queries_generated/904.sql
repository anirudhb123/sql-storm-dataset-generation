WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(c.Score, 0)) AS TotalComments,
        SUM(COALESCE(v.VoteTypeId = 2::smallint, 0)::int) AS Upvotes,
        SUM(COALESCE(v.VoteTypeId = 3::smallint, 0)::int) AS Downvotes,
        RANK() OVER (ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS PostRow
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' 
        AND p.ViewCount > 100
    GROUP BY 
        p.Id, u.DisplayName
)
SELECT 
    ue.DisplayName AS UserName,
    ue.PostCount,
    ue.TotalViews,
    ue.TotalComments,
    ue.Upvotes,
    ue.Downvotes,
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CommentCount,
    CASE 
        WHEN ue.UserRank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory
FROM 
    UserEngagement ue
LEFT JOIN 
    TopPosts tp ON ue.UserId = tp.Author
WHERE 
    tp.PostRow = 1 OR tp.PostRow IS NULL
ORDER BY 
    ue.TotalViews DESC, ue.Upvotes DESC;
