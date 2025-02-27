WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        STRING_AGG(tag.TagName, ', ') AS Tags
    FROM 
        RankedPosts rp
    JOIN 
        Tags tag ON POSITION(tag.TagName IN rp.Tags) > 0
    WHERE 
        rp.TagRank <= 5
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(c.Id) AS CommentsCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    pe.Title,
    pe.CreationDate,
    pe.Score,
    pe.ViewCount,
    ue.DisplayName,
    ue.PostsCount,
    ue.CommentsCount,
    ue.Upvotes,
    ue.Downvotes
FROM 
    TopPosts pe
JOIN 
    UserEngagement ue ON pe.PostId = (SELECT id FROM Posts WHERE OwnerUserId = ue.UserId LIMIT 1)
ORDER BY 
    pe.Score DESC, ue.Upvotes DESC
LIMIT 50;
