WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagPostCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON t.Id = pt.Tags::jsonb::text[]
    GROUP BY 
        t.TagName
    ORDER BY 
        TagPostCount DESC
    LIMIT 5
)
SELECT 
    up.DisplayName AS UserName,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    ua.TotalPosts,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    tt.TagName
FROM 
    RankedPosts rp
JOIN 
    UserActivity ua ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ua.UserId)
LEFT JOIN 
    TopTags tt ON tt.TagPostCount > 0
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, ua.TotalUpvotes DESC;
