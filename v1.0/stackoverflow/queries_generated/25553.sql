WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON true
    WHERE 
        p.PostTypeId = 1 -- Considering only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount
), 
UserMetrics AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViewCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.TagsArray,
        um.UserId,
        um.Reputation
    FROM 
        RankedPosts rp
    JOIN 
        Users um ON rp.UserId = um.Id
    WHERE 
        rp.UserPostRank <= 3 -- Select top 3 questions per user
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.TagsArray,
    um.TotalPosts,
    um.TotalViewCount,
    um.Reputation
FROM 
    TopPosts tp
JOIN 
    UserMetrics um ON tp.UserId = um.UserId
WHERE 
    um.TotalPosts > 0 -- Ensure users have posts
ORDER BY 
    tp.ViewCount DESC, 
    um.TotalViewCount DESC;
