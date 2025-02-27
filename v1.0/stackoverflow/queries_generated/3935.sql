WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Created within the last year
    GROUP BY 
        p.Id
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 5 -- More than 5 questions
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CommentCount,
        u.DisplayName
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
    WHERE 
        rp.PostRank <= 3 -- Top 3 posts per user
)

SELECT 
    t.UserId,
    t.DisplayName,
    COALESCE(tp.Title, 'No posts') AS TopPostTitle,
    COALESCE(tp.CommentCount, 0) AS TopPostComments,
    COALESCE(tp.ViewCount, 0) AS TopPostViews,
    u.TotalBounties
FROM 
    TopUsers u
LEFT JOIN 
    TopPosts tp ON u.UserId = tp.PostId
ORDER BY 
    u.TotalBounties DESC,
    u.QuestionCount DESC;
